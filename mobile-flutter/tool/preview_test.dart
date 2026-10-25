import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:acopio_flutter/main.dart';
import 'package:acopio_flutter/core/providers.dart';
import 'package:acopio_flutter/services/api_client.dart';
import 'package:acopio_flutter/services/session_service.dart';
import 'package:acopio_flutter/services/sync_service.dart';
import 'package:acopio_flutter/viewmodels/app_viewmodels.dart';
import '../test/support.dart';
import '../test/widget_test.dart' show MemoryLocal;

void main() {
  testWidgets('renderiza pantallas con datos de prueba para revisión visual', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final config = File('.dart_tool/package_config.json');
      final packages =
          jsonDecode(await config.readAsString())['packages'] as List;
      final root = config.absolute.uri.resolve(
        packages.firstWhere((p) => p['name'] == 'flutter')['rootUri'],
      );
      final sdk = Directory.fromUri(root).parent.parent.path;
      for (final pair in [
        ('Roboto', 'roboto-regular.ttf'),
        ('MaterialIcons', 'materialicons-regular.otf'),
      ]) {
        final loader = FontLoader(pair.$1)
          ..addFont(
            File(
              '$sdk/bin/cache/artifacts/material_fonts/${pair.$2}',
            ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
        await loader.load();
      }
    });
    tester.view.physicalSize = const Size(430, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    final s = session();
    final local = MemoryLocal();
    final api = ApiClient(client: MockClient((_) async => response({}, 401)));
    final service = SessionService(api, local, MemorySessionStore());
    final auth = AuthViewModel(service)..booting = false;
    final vm = WorkspaceViewModel(s, local, service, SyncService(api, local))
      ..ready = true
      ..catalogs = cache()
      ..editionState = 'Guardado en el dispositivo';
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('docs/screenshots/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          workspaceProvider(s).overrideWith((ref) => vm),
          localProvider.overrideWithValue(local),
        ],
        child: RepaintBoundary(key: boundary, child: const AcopioApp()),
      ),
    );
    await shot('acceso');
    auth.session = s;
    auth.emit();
    await shot('inicio');
    await tester.tap(find.text('Nueva recepción').first);
    await tester.pumpAndSettle();
    vm.select('proveedor', cache().suppliers.first);
    vm.select('vehiculo', cache().vehicles.first);
    await tester.ensureVisible(find.byKey(const Key('capture-next')));
    await tester.tap(find.byKey(const Key('capture-next')));
    await tester.pumpAndSettle();
    await shot('mediciones');
  });
}
