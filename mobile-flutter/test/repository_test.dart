import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:acopio_flutter/repositories/local_repository.dart';
import 'package:acopio_flutter/models/lot.dart';
import 'support.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late LocalRepository repo;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('acopio_flutter_test_');
    repo = LocalRepository(
      factory: databaseFactoryFfi,
      path: '${dir.path}/local.db',
    );
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });
  test('apertura concurrente es idempotente y lista vacía', () async {
    final dbs = await Future.wait([repo.db, repo.db]);
    expect(identical(dbs[0], dbs[1]), isTrue);
    expect(await repo.lots(session()), isEmpty);
  });
  test('captura, UUID v4, mediciones y recuperación al reabrir', () async {
    final s = session();
    final saved = await repo.capture(validForm(), s);
    expect(
      saved.id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(saved.volume, 120.5);
    expect(saved.vehicle, 'ABC-123');
    await repo.close();
    repo = LocalRepository(
      factory: databaseFactoryFfi,
      path: '${dir.path}/local.db',
    );
    final list = await repo.lots(s);
    expect(list.single.id, saved.id);
    expect(list.single.sent, isFalse);
    expect((await repo.send(saved.id))!.request.supplierId, 3);
  });
  test('edición parcial sobrevive cierre sin convertirse en lote', () async {
    final form = {
      ...emptyForm(),
      'proveedor': "Fundo O'Connor",
      'volumen': '12,',
    };
    await repo.saveEdition('1:2', form);
    await repo.close();
    expect(await repo.edition('1:2'), form);
    expect(await repo.lots(session()), isEmpty);
  });
  test('autoguardados rápidos y captura no reviven una edición', () async {
    await Future.wait(
      [
        'F',
        'Fu',
        'Fundo',
      ].map((v) => repo.saveEdition('1:2', {...emptyForm(), 'proveedor': v})),
    );
    expect((await repo.edition('1:2'))!['proveedor'], 'Fundo');
    final saving = repo.saveEdition('1:2', validForm());
    final capture = repo.capture(validForm(), session());
    await Future.wait([saving, capture]);
    expect(await repo.edition('1:2'), isNull);
    expect((await repo.lots(session())).length, 1);
  });
  test('fallo del envío local revierte captura y conserva edición', () async {
    await repo.saveEdition('1:2', validForm());
    await (await repo.db).execute(
      "CREATE TRIGGER fail_send BEFORE INSERT ON sends BEGIN SELECT RAISE(ABORT,'test failure'); END",
    );
    await expectLater(repo.capture(validForm(), session()), throwsException);
    expect(await repo.edition('1:2'), validForm());
    expect(await (await repo.db).query('lots'), isEmpty);
  });
  test('usuario y centro aíslan ediciones y registros', () async {
    await repo.saveEdition('1:2', validForm());
    await repo.saveEdition('3:2', {...validForm(), 'volumen': '80'});
    final saved = await repo.capture(validForm(), session());
    expect(await repo.edition('1:2'), isNull);
    expect((await repo.edition('3:2'))!['volumen'], '80');
    expect(await repo.lots(session(user: 3)), isEmpty);
    expect(await repo.lots(session(center: 3)), isEmpty);
    final req = (await repo.send(saved.id))!.request;
    await expectLater(repo.prepare(req, session(user: 3)), throwsException);
    await expectLater(repo.prepare(req, session(center: 3)), throwsException);
  });
  test(
    'cuerpo congelado rechaza cambios, confirma sin borrar registro',
    () async {
      final saved = await repo.capture(validForm(), session());
      final req = (await repo.send(saved.id))!.request;
      final changed = LotRequest.fromJson({...req.toJson(), 'idProveedor': 8});
      await expectLater(repo.prepare(changed, session()), throwsException);
      await repo.confirm(
        saved.id,
        SendResult.parse(result(saved.id), saved.id),
      );
      expect((await repo.lots(session())).single.sent, isTrue);
      await repo.close();
      expect((await repo.prepare(req, session())).result!.state, 'APROBADO');
    },
  );
  test('descartar edición no elimina recepciones confirmadas', () async {
    final saved = await repo.capture(validForm(), session());
    await repo.saveEdition('1:2', validForm());
    await repo.saveEdition('1:2', emptyForm());
    expect(await repo.edition('1:2'), isNull);
    expect((await repo.lots(session())).single.id, saved.id);
  });
  test('SQL se parametriza y respeta nombres con comillas', () async {
    final name = "Fundo O'Connor; DROP TABLE lots;--";
    await repo.capture({...validForm(), 'proveedor': name}, session());
    expect((await repo.lots(session())).single.supplier, name);
  });
  test('sesión vencida impide captura sin perder formulario', () async {
    await repo.saveEdition('1:2', validForm());
    await expectLater(
      repo.capture(validForm(), session(expiry: 1)),
      throwsException,
    );
    expect(await repo.edition('1:2'), validForm());
    expect(await repo.lots(session()), isEmpty);
  });
}
