import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config.dart';
import '../models/session.dart';
import '../models/catalog.dart';
import '../repositories/local_repository.dart';
import 'api_client.dart';

abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  final FlutterSecureStorage storage;
  static const key = 'acopio.flutter.session.v1';
  SecureSessionStore([FlutterSecureStorage? storage])
    : storage = storage ?? const FlutterSecureStorage();
  @override
  Future<String?> read() => storage.read(key: key);
  @override
  Future<void> write(String value) => storage.write(key: key, value: value);
  @override
  Future<void> clear() => storage.delete(key: key);
}

class SessionService {
  final ApiClient api;
  final LocalRepository local;
  final SessionStore store;
  SessionService(this.api, this.local, this.store);
  Future<Session> login(String email, String password) async {
    if (!AppConfig.authPath.startsWith('/') ||
        AppConfig.authPath.startsWith('//')) {
      throw const AppFailure(
        'La ruta de autenticación debe ser relativa a la API.',
      );
    }
    try {
      final session = Session.fromJson(
        await api.request(
          AppConfig.authPath,
          body: {'email': email.trim(), 'password': password},
          timeout: const Duration(seconds: 10),
        ),
      );
      if (!session.isValid) {
        throw const AppFailure('La sesión recibida ya venció.');
      }
      await refreshCatalogs(session);
      await store.write(jsonEncode(session.toJson()));
      return session;
    } on AppFailure catch (e) {
      if (e.status == 401) {
        throw const AppFailure('Correo o contraseña incorrectos.', 401);
      }
      rethrow;
    }
  }

  Future<CatalogCache> refreshCatalogs(Session session) async {
    if (!session.isValid) {
      throw const AppFailure(
        'Tu sesión venció. Inicia sesión con la misma cuenta para actualizar los catálogos.',
      );
    }
    final lists = await Future.wait([
      allCatalog(session, 'proveedores'),
      allCatalog(session, 'vehiculos'),
    ]);
    final center = await api.request(
      '/api/catalogos/centro',
      token: session.token,
    );
    if (center['id'] != session.centerId ||
        center['nombre'] is! String ||
        center['region'] is! String ||
        center['capacidadLitros'] is! num) {
      throw const AppFailure(
        'El centro de la sesión cambió o no es válido. Inicia sesión nuevamente.',
      );
    }
    final cache = CatalogCache(
      lists[0],
      lists[1],
      center,
      DateTime.now().toUtc().toIso8601String(),
    );
    // La copia anterior sigue disponible hasta completar toda la descarga.
    await local.saveConfig('catalogs:${session.key}', cache.toJson());
    return cache;
  }

  Future<ApiPage<CatalogItem>> catalog(
    Session s,
    String type, {
    String search = '',
    int page = 0,
  }) async {
    final result = ApiPage<CatalogItem>.parse(
      await api.request(
        '/api/catalogos/$type?buscar=${Uri.encodeQueryComponent(search)}&pagina=$page&tamano=25',
        token: s.token,
      ),
      (j) => CatalogItem.parse(j, type),
    );
    if (result.page != page || result.size != 25) {
      throw const AppFailure('El servidor devolvió una página no válida.');
    }
    return result;
  }

  Future<List<CatalogItem>> allCatalog(Session s, String type) async {
    final items = <CatalogItem>[];
    for (var page = 0; page < 400; page++) {
      final result = await catalog(s, type, page: page);
      items.addAll(result.items);
      if (items.length >= result.total) {
        return items;
      }
      if (result.items.isEmpty) {
        break;
      }
    }
    throw const AppFailure(
      'El catálogo es demasiado grande o cambió durante la descarga. Reintenta.',
    );
  }

  Future<CatalogCache?> cached(Session s) async {
    final json = await local.config('catalogs:${s.key}');
    if (json == null) {
      return null;
    }
    final cache = CatalogCache.fromJson(json);
    return cache.center['id'] == s.centerId ? cache : null;
  }

  Future<Session?> restore() async {
    final raw = await store.read();
    if (raw == null) {
      return null;
    }
    Session session;
    try {
      session = Session.fromJson(jsonDecode(raw));
    } catch (_) {
      await store.clear();
      return null;
    }
    if (!session.isValid) {
      await store.clear();
      return null;
    }
    return await cached(session) == null ? null : session;
  }

  Future<void> logout() => store.clear();
}
