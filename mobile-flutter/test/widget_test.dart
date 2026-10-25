import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:acopio_flutter/main.dart';
import 'package:acopio_flutter/core/providers.dart';
import 'package:acopio_flutter/models/session.dart';
import 'package:acopio_flutter/models/lot.dart';
import 'package:acopio_flutter/repositories/local_repository.dart';
import 'package:acopio_flutter/services/api_client.dart';
import 'package:acopio_flutter/services/session_service.dart';
import 'package:acopio_flutter/services/sync_service.dart';
import 'package:acopio_flutter/viewmodels/app_viewmodels.dart';
import 'support.dart';

class MemoryLocal extends LocalRepository {
  MemoryLocal() : super(factory: databaseFactoryFfi);
  Map<String, String>? saved;
  List<LocalLot> records = [];
  @override
  Future<void> saveEdition(String key, Map<String, String> value) async {
    saved = Map.of(value);
  }

  @override
  Future<LocalLot> capture(Map<String, String> form, Session session) async {
    final lot = LocalLot.fromRow({
      'id': 'f4a1ba39-6c18-411a-9657-859c301ded22',
      'fecha': '2026-10-24T12:00:00Z',
      'proveedor': form['proveedor'],
      'vehiculo': form['vehiculo'],
      'centro': form['centro'],
      'volumen': 120.5,
      'temperatura': 4.5,
      'acidez': 16.0,
      'densidad': 1.03,
    });
    records.add(lot);
    saved = null;
    return lot;
  }

  @override
  Future<List<LocalLot>> lots(Session session) async => records;
  @override
  Future<PreparedSend?> send(String id) async => null;
}

void main() {
  Future<(AuthViewModel, WorkspaceViewModel)> mount(
    WidgetTester tester, {
    bool loggedIn = true,
    Session? userSession,
  }) async {
    final local = MemoryLocal(),
        api = ApiClient(client: MockClient((_) async => response({}, 401))),
        s = userSession ?? session();
    final service = SessionService(api, local, MemorySessionStore());
    final auth = AuthViewModel(service)
      ..booting = false
      ..session = loggedIn ? s : null;
    final vm = WorkspaceViewModel(s, local, service, SyncService(api, local))
      ..ready = true
      ..catalogs = cache()
      ..editionState = 'Guardado en el dispositivo';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiProvider.overrideWithValue(api),
          authProvider.overrideWith((ref) => auth),
          workspaceProvider(s).overrideWith((ref) => vm),
          localProvider.overrideWithValue(local),
        ],
        child: const AcopioApp(),
      ),
    );
    await tester.pumpAndSettle();
    return (auth, vm);
  }

  testWidgets('login valida antes de enviar credenciales', (tester) async {
    await mount(tester, loggedIn: false);
    expect(find.text('Servidor en línea'), findsNothing);
    expect(find.text('Servidor sin conexión'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un correo válido.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
  });
  testWidgets('navegación, catálogo local y formulario de tres pasos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (_, vm) = await mount(tester);
    await tester.tap(find.text('Nueva recepción').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-next')));
    await tester.pumpAndSettle();
    expect(
      find.text('Selecciona proveedor y vehículo del catálogo descargado.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('select-supplier')));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Fundo O'Connor"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('select-vehicle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABC-123'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-next')));
    await tester.pumpAndSettle();
    for (final pair in [
      ('volumen', '120,50'),
      ('temperatura', '4,5'),
      ('acidez', '16'),
      ('densidad', '1,0300'),
    ]) {
      await tester.enterText(find.byKey(ValueKey('${pair.$1}-0')), pair.$2);
    }
    await tester.tap(find.byKey(const Key('capture-next')));
    await tester.pumpAndSettle();
    expect(find.text('Paso 3 de 3 · Revisión'), findsOneWidget);
    await tester.tap(find.byKey(const Key('capture-next')));
    await tester.pumpAndSettle();
    expect(find.text('Detalle local'), findsOneWidget);
    expect(vm.lots.length, 1);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registros').last);
    await tester.pumpAndSettle();
    expect(find.text("Fundo O'Connor"), findsOneWidget);
  });
  testWidgets('revisión de recepción permite nombres largos sin desbordar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final base = session();
    final s = Session(
      token: base.token,
      name: base.name,
      centerName: 'Centro de prueba académico',
      userId: base.userId,
      centerId: base.centerId,
    );
    final (_, vm) = await mount(tester, userSession: s);
    vm.form = {...validForm(), 'proveedor': 'Establo Lechero Los Andes S.A.C.'};
    await tester.tap(find.text('Nueva recepción').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-next')));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expect(find.text('Centro: Centro de prueba académico'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cerrar sesión conserva edición y vuelve al acceso', (
    tester,
  ) async {
    final (_, vm) = await mount(tester);
    vm.form = validForm();
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Acceso de operarios'), findsOneWidget);
    expect((vm.local as MemoryLocal).saved, validForm());
  });
  testWidgets('pantalla estrecha y texto grande no desbordan', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester);
    expect(tester.takeException(), isNull);
  });
  testWidgets('acceso estrecho con texto grande permite llegar al botón', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester, loggedIn: false);
    await tester.scrollUntilVisible(
      find.byKey(const Key('login-submit')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
