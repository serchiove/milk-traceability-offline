import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:acopio_flutter/repositories/local_repository.dart';
import 'package:acopio_flutter/services/api_client.dart';
import 'package:acopio_flutter/services/session_service.dart';
import 'package:acopio_flutter/services/sync_service.dart';
import 'package:acopio_flutter/services/central_service.dart';
import 'support.dart';

void main() {
  final base = Platform.environment['ACOPIO_TEST_API'];
  test(
    'contrato real: login, captura, SHA256, replay, QR y asignación',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('acopio_contract_');
      final local = LocalRepository(
        factory: databaseFactoryFfi,
        path: '${dir.path}/contract.db',
      );
      final api = ApiClient(baseUrl: base);
      try {
        final auth = SessionService(api, local, MemorySessionStore());
        final s = await auth.login('operario@gloria.com.pe', '123456');
        final catalog = (await auth.cached(s))!;
        final form = {
          ...validForm(),
          'proveedor': catalog.suppliers.first.label,
          'vehiculo': catalog.vehicles.first.label,
          'centro': s.centerName,
          'idProveedor': '${catalog.suppliers.first.id}',
          'idVehiculo': '${catalog.vehicles.first.id}',
        };
        final lot = await local.capture(form, s);
        final req = (await local.send(lot.id))!.request;
        final result = await SyncService(api, local).send(s, req);
        expect(result.state, 'APROBADO');
        final replay = await api.request(
          '/api/lotes',
          token: s.token,
          body: {
            ...req.toJson(),
            'huellaSolicitud': req.fingerprint(s.userId, s.centerId),
          },
        );
        expect(replay['idempotente'], true);
        final central = CentralService(api);
        expect((await central.detail(s, result.qr!))['idLote'], lot.id);
        final tanks = await central.tanks(s);
        final tank = tanks.items.first;
        expect(
          (await central.assign(s, lot.id, tank['id']))['idTanque'],
          tank['id'],
        );
        final after = (await central.tanks(
          s,
        )).items.firstWhere((t) => t['id'] == tank['id']);
        expect(
          after['volumenAsignadoLitros'],
          (tank['volumenAsignadoLitros'] as num) + 120.5,
        );
        await central.assign(s, lot.id, tank['id']);
        final repeated = (await central.tanks(
          s,
        )).items.firstWhere((t) => t['id'] == tank['id']);
        expect(
          repeated['volumenAsignadoLitros'],
          after['volumenAsignadoLitros'],
        );
        await local.close();
        expect((await local.lots(s)).single.id, lot.id);
        expect((await auth.restore())!.key, s.key);
        final jefe = await api.request(
          '/api/auth/login',
          body: {'email': 'jefatura@gloria.com.pe', 'password': '123456'},
        );
        final report = await api.request(
          '/api/reportes',
          token: jefe['accessToken'],
        );
        expect(report['total'], 1);
        expect(report['volumenLitros'], 120.5);
      } finally {
        api.close();
        await local.close();
        await dir.delete(recursive: true);
      }
    },
    skip: base == null
        ? 'Define ACOPIO_TEST_API con un backend y una base de pruebas aislados.'
        : false,
  );
}
