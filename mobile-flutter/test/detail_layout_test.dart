import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:acopio_flutter/core/providers.dart';
import 'package:acopio_flutter/core/theme.dart';
import 'package:acopio_flutter/models/lot.dart';
import 'package:acopio_flutter/repositories/local_repository.dart';
import 'package:acopio_flutter/services/api_client.dart';
import 'package:acopio_flutter/services/session_service.dart';
import 'package:acopio_flutter/services/sync_service.dart';
import 'package:acopio_flutter/viewmodels/app_viewmodels.dart';
import 'package:acopio_flutter/views/central_view.dart';
import 'package:acopio_flutter/views/local_detail_view.dart';
import 'package:acopio_flutter/models/session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'support.dart';

const lotId = '82918796-21e2-48e7-b7ea-123456789abc';
const centerName = 'Centro de prueba académico';
final detail = <String, dynamic>{
  'idLote': lotId,
  'proveedor': 'Establo Lechero Los Andes S.A.C.',
  'placa': 'V1A-450',
  'centro': centerName,
  'operario': 'Juan Pérez',
  'fechaHora': '2026-10-25T01:08:00Z',
  'volumenLitros': 115,
  'temperaturaC': 5,
  'acidezDornic': 15,
  'densidadGml': 1.03,
  'estadoEvaluacion': 'APROBADO',
  'versionReglas': 'DEMO-1',
};
final request = LotRequest(
  id: lotId,
  date: detail['fechaHora'],
  supplierId: 3,
  vehicleId: 4,
  volume: 115,
  temperature: 5,
  acidity: 15,
  density: 1.03,
);

class DetailLocal extends LocalRepository {
  DetailLocal() : super(factory: databaseFactoryFfi);
  @override
  Future<PreparedSend?> send(String id) async =>
      PreparedSend(request, 1, 2, SendResult.parse(result(lotId), lotId));
}

void main() {
  for (final width in [360.0, 320.0]) {
    for (final central in [false, true]) {
      testWidgets(
        '${central ? 'trazabilidad' : 'detalle recibido'} sin overflow a $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final base = session();
          final s = Session(
            token: base.token,
            name: 'Juan Pérez',
            centerName: centerName,
            userId: 1,
            centerId: 2,
          );
          final api = ApiClient(
            client: MockClient((_) async => response(detail)),
          );
          final local = DetailLocal();
          final service = SessionService(api, local, MemorySessionStore());
          final vm = WorkspaceViewModel(
            s,
            local,
            service,
            SyncService(api, local),
          )..ready = true;
          final lot = LocalLot.fromRow({
            'id': lotId,
            'fecha': detail['fechaHora'],
            'proveedor': detail['proveedor'],
            'vehiculo': 'V1A-450',
            'centro': centerName,
            'volumen': 115.0,
            'temperatura': 5.0,
            'acidez': 15.0,
            'densidad': 1.03,
          });
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                apiProvider.overrideWithValue(api),
                localProvider.overrideWithValue(local),
                workspaceProvider(s).overrideWith((ref) => vm),
              ],
              child: MaterialApp(
                theme: acopioTheme(),
                locale: const Locale('es', 'PE'),
                supportedLocales: const [Locale('es', 'PE')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: central
                    ? CentralView(session: s, initialCode: lotId)
                    : LocalDetailView(session: s, lot: lot),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('APROBADO'), findsOneWidget);
          if (central) {
            expect(find.text('Operario: Juan Pérez'), findsOneWidget);
            expect(find.text('Centro: $centerName'), findsOneWidget);
          } else {
            expect(find.text('RECIBIDO POR SERVIDOR'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
