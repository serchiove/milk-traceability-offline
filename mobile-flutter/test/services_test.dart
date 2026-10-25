import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:acopio_flutter/core/config.dart';
import 'package:acopio_flutter/models/session.dart';
import 'package:acopio_flutter/repositories/local_repository.dart';
import 'package:acopio_flutter/services/api_client.dart';
import 'package:acopio_flutter/services/session_service.dart';
import 'package:acopio_flutter/services/sync_service.dart';
import 'package:acopio_flutter/services/central_service.dart';
import 'support.dart';
import 'package:acopio_flutter/viewmodels/app_viewmodels.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late LocalRepository repo;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('acopio_services_');
    repo = LocalRepository(
      factory: databaseFactoryFfi,
      path: '${dir.path}/local.db',
    );
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });
  test(
    'actualiza catálogos sin perder borrador y conserva copia si falla',
    () async {
      final s = session();
      final original = cache();
      await repo.saveConfig('catalogs:${s.key}', original.toJson());
      await repo.saveEdition(s.key, validForm());
      var fail = true;
      final api = ApiClient(
        client: MockClient((r) async {
          if (r.url.path.endsWith('/centro')) return response(center);
          if (r.url.path.endsWith('/vehiculos') && fail) {
            throw http.ClientException('offline');
          }
          return response({
            'elementos': [
              r.url.path.endsWith('/proveedores')
                  ? {...supplier, 'id': 99}
                  : vehicle,
            ],
            'total': 1,
            'pagina': 0,
            'tamano': 25,
          });
        }),
      );
      addTearDown(api.close);
      final service = SessionService(api, repo, MemorySessionStore());
      final vm = WorkspaceViewModel(s, repo, service, SyncService(api, repo));
      addTearDown(vm.dispose);
      await vm.initialize();
      expect(await vm.refreshCatalogs(), isFalse);
      expect((await service.cached(s))!.suppliers.single.id, 3);
      expect(vm.catalogs!.updated, original.updated);
      fail = false;
      expect(await vm.refreshCatalogs(), isTrue);
      expect(vm.catalogs!.suppliers.single.id, 99);
      expect((await service.cached(s))!.suppliers.single.id, 99);
      expect(await repo.edition(s.key), validForm());
      expect(vm.form, validForm());
    },
  );

  test(
    'envío parcial cuenta rechazo como enviado y reintenta solo pendiente',
    () async {
      final s = session();
      final first = await repo.capture(validForm(), s);
      final second = await repo.capture(validForm(), s);
      var failSecond = true;
      final bodies = <String, List<String>>{};
      final api = ApiClient(
        client: MockClient((r) async {
          final id = jsonDecode(r.body)['idLote'] as String;
          bodies.putIfAbsent(id, () => []).add(r.body);
          if (id == second.id && failSecond) {
            throw http.ClientException('offline');
          }
          return response(
            result(id, state: id == first.id ? 'RECHAZADO' : 'APROBADO'),
            201,
          );
        }),
      );
      addTearDown(api.close);
      final vm = WorkspaceViewModel(
        s,
        repo,
        SessionService(api, repo, MemorySessionStore()),
        SyncService(api, repo),
      );
      addTearDown(vm.dispose);
      await vm.initialize();
      final batch = vm.sendAll();
      expect(await vm.sendAll(), isNull);
      final summary = (await batch)!;
      expect(summary.confirmed, 1);
      expect(summary.rejected, 1);
      expect(summary.failures.keys, [second.id]);
      expect(vm.pending, 1);
      failSecond = false;
      final retry = (await vm.sendAll())!;
      expect(retry.confirmed, 1);
      expect(retry.approved, 1);
      expect(retry.failures, isEmpty);
      expect(vm.pending, 0);
      expect(bodies[first.id]!.length, 1);
      expect(bodies[second.id]![0], bodies[second.id]![1]);
    },
  );
  test(
    'persiste antes de HTTP y rechazo de calidad cuenta como enviado',
    () async {
      final s = session();
      final lot = await repo.capture(validForm(), s);
      final req = (await repo.send(lot.id))!.request;
      var calls = 0;
      final api = ApiClient(
        client: MockClient((r) async {
          calls++;
          expect((await repo.send(lot.id))!.result, isNull);
          expect(r.headers['Authorization'], 'Bearer ${s.token}');
          expect(jsonDecode(r.body)['huellaSolicitud'], req.fingerprint(1, 2));
          return response(result(lot.id, state: 'RECHAZADO'), 201);
        }),
      );
      final sync = SyncService(api, repo);
      expect((await sync.send(s, req)).state, 'RECHAZADO');
      await sync.send(s, req);
      expect(calls, 1);
      expect((await repo.lots(s)).single.sent, isTrue);
    },
  );
  test(
    'fallo de red y reintento mantienen exactamente UUID y cuerpo',
    () async {
      final s = session();
      final lot = await repo.capture(validForm(), s);
      final req = (await repo.send(lot.id))!.request;
      final bodies = <String>[];
      final sync = SyncService(
        ApiClient(
          client: MockClient((r) async {
            bodies.add(r.body);
            if (bodies.length == 1) {
              throw http.ClientException('network');
            }
            return response(result(lot.id, replay: true));
          }),
        ),
        repo,
      );
      await expectLater(sync.send(s, req), throwsA(isA<AppFailure>()));
      expect((await repo.send(lot.id))!.result, isNull);
      expect((await sync.send(s, req)).json['idempotente'], isTrue);
      expect(bodies[0], bodies[1]);
    },
  );
  test('doble toque simultáneo produce una sola petición', () async {
    final s = session();
    final lot = await repo.capture(validForm(), s);
    final req = (await repo.send(lot.id))!.request;
    var count = 0;
    final sync = SyncService(
      ApiClient(
        client: MockClient((r) async {
          count++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return response(result(lot.id));
        }),
      ),
      repo,
    );
    await Future.wait([sync.send(s, req), sync.send(s, req)]);
    expect(count, 1);
  });
  test('409, UUID ajeno y JSON inválido no confirman registro', () async {
    for (final resp in [
      response({}, 409),
      response(result('wrong')),
      http.Response('invalid', 200),
    ]) {
      final s = session();
      final lot = await repo.capture(validForm(), s);
      final req = (await repo.send(lot.id))!.request;
      await expectLater(
        SyncService(
          ApiClient(client: MockClient((_) async => resp)),
          repo,
        ).send(s, req),
        throwsException,
      );
      expect((await repo.send(lot.id))!.result, isNull);
    }
  });
  test('errores HTTP y tiempo agotado se distinguen', () async {
    for (final status in [400, 401, 403, 404, 409, 429, 500]) {
      await expectLater(
        ApiClient(
          client: MockClient((_) async => response({}, status)),
        ).request('/api/lotes'),
        throwsA(isA<AppFailure>().having((e) => e.status, 'status', status)),
      );
    }
    await expectLater(
      ApiClient(
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return response({});
        }),
      ).request('/api/lotes'),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.message,
          'mensaje',
          contains('tiempo'),
        ),
      ),
    );
  });
  test(
    'login descarga catálogos antes de guardar sesión y admite acceso offline',
    () async {
      final s = session();
      final store = MemorySessionStore();
      final api = ApiClient(
        client: MockClient((r) async {
          if (r.url.path == '/api/auth/login') {
            expect(jsonDecode(r.body), {
              'email': 'op@example.com',
              'password': 'test',
            });
            return response(s.toJson());
          }
          expect(store.value, isNull);
          expect(r.headers['Authorization'], 'Bearer ${s.token}');
          if (r.url.path.endsWith('/centro')) {
            return response(center);
          }
          return response({
            'elementos': [
              r.url.path.endsWith('/proveedores') ? supplier : vehicle,
            ],
            'total': 1,
            'pagina': 0,
            'tamano': 25,
          });
        }),
      );
      final service = SessionService(api, repo, store);
      await service.login(' op@example.com ', 'test');
      expect((await service.restore())!.key, '1:2');
      await repo.close();
      expect((await service.restore())!.name, s.name);
      await service.logout();
      expect(await service.restore(), isNull);
      expect(await service.cached(s), isNotNull);
    },
  );
  test('sin catálogo o con token vencido no hay acceso offline', () async {
    final store = MemorySessionStore();
    final service = SessionService(ApiClient(), repo, store);
    store.value = jsonEncode(session().toJson());
    expect(await service.restore(), isNull);
    store.value = jsonEncode(session(expiry: 1).toJson());
    expect(await service.restore(), isNull);
    expect(store.value, isNull);
  });
  test(
    'rol ajeno, respuesta incompleta o centro diferente no autoriza dispositivo',
    () async {
      final s = session();
      expect(
        () => Session.fromJson({
          ...s.toJson(),
          'usuario': {...(s.toJson()['usuario'] as Map), 'rol': 'JEFATURA'},
        }),
        throwsException,
      );
      expect(() => Session.fromJson({'accessToken': 'x'}), throwsException);
      final store = MemorySessionStore();
      final api = ApiClient(
        client: MockClient((r) async {
          if (r.url.path.endsWith('/login')) {
            return response(s.toJson());
          }
          if (r.url.path.endsWith('/centro')) {
            return response({...center, 'id': 9});
          }
          return response({
            'elementos': [],
            'total': 0,
            'pagina': 0,
            'tamano': 25,
          });
        }),
      );
      await expectLater(
        SessionService(api, repo, store).login('a', 'b'),
        throwsException,
      );
      expect(store.value, isNull);
    },
  );
  test(
    '401 login informa credenciales; conexión no afirma contraseña incorrecta',
    () async {
      final store = MemorySessionStore();
      await expectLater(
        SessionService(
          ApiClient(client: MockClient((_) async => response({}, 401))),
          repo,
          store,
        ).login('a', 'b'),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.message,
            'mensaje',
            contains('incorrectos'),
          ),
        ),
      );
      await expectLater(
        SessionService(
          ApiClient(
            client: MockClient(
              (_) async => throw http.ClientException('network'),
            ),
          ),
          repo,
          store,
        ).login('a', 'b'),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.message,
            'mensaje',
            isNot(contains('incorrectos')),
          ),
        ),
      );
    },
  );
  test('catálogo codifica búsqueda y valida página de la API', () async {
    final service = SessionService(
      ApiClient(
        client: MockClient((r) async {
          expect(r.url.queryParameters['buscar'], 'ABC&?');
          expect(r.url.queryParameters['pagina'], '1');
          return response({
            'elementos': [vehicle],
            'total': 26,
            'pagina': 1,
            'tamano': 25,
          });
        }),
      ),
      repo,
      MemorySessionStore(),
    );
    expect(
      (await service.catalog(
        session(),
        'vehiculos',
        search: 'ABC&?',
        page: 1,
      )).items.single.label,
      'ABC-123',
    );
    final malformed = SessionService(
      ApiClient(
        client: MockClient(
          (r) async => response({
            'elementos': [null],
            'total': 1,
            'pagina': 0,
            'tamano': 25,
          }),
        ),
      ),
      repo,
      MemorySessionStore(),
    );
    await expectLater(
      malformed.catalog(session(), 'proveedores'),
      throwsException,
    );
  });
  test(
    'asignación consulta antes; reintento no reasigna lote confirmado',
    () async {
      final id = 'f4a1ba39-6c18-411a-9657-859c301ded22';
      final calls = <String>[];
      var assigned = false;
      final central = CentralService(
        ApiClient(
          client: MockClient((r) async {
            calls.add(r.method);
            if (r.method == 'POST') {
              assigned = true;
              expect(jsonDecode(r.body), {'idTanque': 1});
              return response({});
            }
            return response({'idLote': id, 'idTanque': assigned ? 1 : null});
          }),
        ),
      );
      await central.assign(session(), id, 1);
      expect(calls, ['GET', 'POST', 'GET']);
      calls.clear();
      await central.assign(session(), id, 1);
      expect(calls, ['GET']);
    },
  );
  test(
    'trazabilidad QR usa ruta real y rechaza código inválido sin HTTP',
    () async {
      var calls = 0;
      const id = 'f4a1ba39-6c18-411a-9657-859c301ded22';
      final central = CentralService(
        ApiClient(
          client: MockClient((r) async {
            calls++;
            expect(r.url.path, '/api/lotes/por-qr');
            expect(r.url.queryParameters['codigo'], 'ACOPIO:$id');
            return response({'idLote': id});
          }),
        ),
      );
      await central.detail(session(), 'ACOPIO:$id');
      await expectLater(central.detail(session(), 'bad'), throwsException);
      expect(calls, 1);
    },
  );
}
