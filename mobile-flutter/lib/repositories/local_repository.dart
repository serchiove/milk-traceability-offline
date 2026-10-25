import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/config.dart';
import '../models/lot.dart';
import '../models/session.dart';

/// Almacenamiento SQLite de la app, con registros y ediciones por usuario y centro.
class LocalRepository {
  final DatabaseFactory factory;
  final String? path;
  Future<Database>? _opening;
  Future<void> _writes = Future.value();
  LocalRepository({DatabaseFactory? factory, this.path})
    : factory = factory ?? databaseFactory;
  Future<Database> get db => _opening ??= _open().catchError((Object e) {
    _opening = null;
    throw e;
  });
  Future<Database> _open() async => factory.openDatabase(
    path ?? p.join(await factory.getDatabasesPath(), 'acopio_flutter.db'),
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE lots (id TEXT PRIMARY KEY,fecha TEXT NOT NULL,proveedor TEXT NOT NULL,vehiculo TEXT NOT NULL,centro TEXT NOT NULL,volumen REAL NOT NULL CHECK(volumen>0),temperatura REAL NOT NULL,acidez REAL NOT NULL CHECK(acidez>=0),densidad REAL NOT NULL CHECK(densidad>0))',
        );
        await db.execute(
          'CREATE TABLE sends (id TEXT PRIMARY KEY REFERENCES lots(id),usuario INTEGER NOT NULL,centro INTEGER NOT NULL,solicitud TEXT NOT NULL,resultado TEXT)',
        );
        await db.execute(
          'CREATE TABLE editions (clave TEXT PRIMARY KEY,formulario TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE config (clave TEXT PRIMARY KEY,contenido TEXT NOT NULL)',
        );
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys=ON');
      },
    ),
  );
  Future<T> _queue<T>(Future<T> Function() work) {
    final task = _writes.then((_) => work());
    _writes = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<void> flush() => _writes;
  Future<void> close() async {
    await flush();
    if (_opening != null) {
      await (await db).close();
      _opening = null;
    }
  }

  Future<Map<String, dynamic>?> config(String key) async {
    final rows = await (await db).query(
      'config',
      where: 'clave=?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : jsonDecode(rows.first['contenido'] as String);
  }

  Future<void> saveConfig(String key, Map<String, dynamic> value) =>
      _queue(() async {
        await (await db).insert('config', {
          'clave': key,
          'contenido': jsonEncode(value),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
  Future<Map<String, String>?> edition(String key) async {
    final rows = await (await db).query(
      'editions',
      where: 'clave=?',
      whereArgs: [key],
    );
    if (rows.isEmpty) {
      return null;
    }
    final value = jsonDecode(rows.first['formulario'] as String);
    if (value is! Map ||
        [...originFields, ...measureFields].any((k) => value[k] is! String)) {
      throw const AppFailure('No se pudo recuperar la recepción en edición.');
    }
    return Map<String, String>.from(value);
  }

  Future<void> saveEdition(String key, Map<String, String> value) {
    final encoded = jsonEncode(
      value,
    ); // Snapshot now, before entering the queue.
    final empty = value.values.every((v) => v.trim().isEmpty);
    return _queue(() async {
      final database = await db;
      if (empty) {
        await database.delete('editions', where: 'clave=?', whereArgs: [key]);
      } else {
        await database.insert('editions', {
          'clave': key,
          'formulario': encoded,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<LocalLot> capture(Map<String, String> form, Session session) {
    final f = Map<String, String>.from(form);
    return _queue(() async {
      if (!session.isValid) {
        throw const AppFailure('La sesión venció. La edición se conserva.');
      }
      if (validateLot(f).isNotEmpty) {
        throw const AppFailure('Revisa los campos de la recepción.');
      }
      final supplier = int.tryParse(f['idProveedor'] ?? '');
      final vehicle = int.tryParse(f['idVehiculo'] ?? '');
      if (supplier == null ||
          vehicle == null ||
          supplier <= 0 ||
          vehicle <= 0) {
        throw const AppFailure('Selecciona proveedor y vehículo del catálogo.');
      }
      double n(String k) => double.parse(f[k]!.trim().replaceFirst(',', '.'));
      final id = const Uuid().v4();
      final date = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
        isUtc: true,
      ).toIso8601String();
      final row = <String, Object?>{
        'id': id,
        'fecha': date,
        'proveedor': f['proveedor']!.trim(),
        'vehiculo': f['vehiculo']!.trim().toUpperCase(),
        'centro': session.centerName,
        'volumen': n('volumen'),
        'temperatura': n('temperatura'),
        'acidez': n('acidez'),
        'densidad': n('densidad'),
      };
      final request = LotRequest(
        id: id,
        date: date,
        supplierId: supplier,
        vehicleId: vehicle,
        volume: n('volumen'),
        temperature: n('temperatura'),
        acidity: n('acidez'),
        density: n('densidad'),
      );
      await (await db).transaction((tx) async {
        await tx.insert('lots', row);
        await tx.insert('sends', {
          'id': id,
          'usuario': session.userId,
          'centro': session.centerId,
          'solicitud': jsonEncode(request.toJson()),
        });
        await tx.delete('editions', where: 'clave=?', whereArgs: [session.key]);
      });
      return LocalLot.fromRow(row);
    });
  }

  Future<List<LocalLot>> lots(Session session) async {
    final rows = await (await db).rawQuery(
      'SELECT l.*,CASE WHEN s.resultado IS NULL THEN 0 ELSE 1 END AS enviado FROM lots l JOIN sends s ON s.id=l.id WHERE s.usuario=? AND s.centro=? ORDER BY l.fecha DESC,l.id DESC',
      [session.userId, session.centerId],
    );
    return rows.map(LocalLot.fromRow).toList();
  }

  Future<PreparedSend?> send(String id) async {
    final rows = await (await db).query(
      'sends',
      where: 'id=?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : PreparedSend.fromRow(rows.first);
  }

  Future<PreparedSend> prepare(LotRequest request, Session session) =>
      _queue(() async {
        final database = await db;
        await database.insert('sends', {
          'id': request.id,
          'usuario': session.userId,
          'centro': session.centerId,
          'solicitud': jsonEncode(request.toJson()),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        final existing = await send(request.id);
        if (existing == null ||
            existing.user != session.userId ||
            existing.center != session.centerId) {
          throw const AppFailure(
            'Esta recepción está vinculada a otro operario o centro.',
          );
        }
        if (jsonEncode(existing.request.toJson()) !=
            jsonEncode(request.toJson())) {
          throw const AppFailure(
            'El envío ya está preparado. Reintenta con los datos originales.',
          );
        }
        return existing;
      });
  Future<void> confirm(String id, SendResult result) => _queue(() async {
    if (result.json['idLote'] != id) {
      throw const AppFailure('La confirmación pertenece a otra recepción.');
    }
    final count = await (await db).update(
      'sends',
      {'resultado': jsonEncode(result.json)},
      where: 'id=?',
      whereArgs: [id],
    );
    if (count != 1) {
      throw const AppFailure(
        'No se pudo conservar la confirmación local. Reintenta el mismo registro.',
      );
    }
  });
}
