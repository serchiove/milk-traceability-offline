import 'dart:convert';
import '../core/config.dart';

class Session {
  final String token, name, centerName;
  final int userId, centerId;
  const Session({
    required this.token,
    required this.name,
    required this.centerName,
    required this.userId,
    required this.centerId,
  });
  String get key => '$userId:$centerId';
  bool validAt(DateTime now) {
    try {
      final payload =
          jsonDecode(
                utf8.decode(
                  base64Url.decode(base64Url.normalize(token.split('.')[1])),
                ),
              )
              as Map;
      final exp = payload['exp'];
      return exp is num &&
          exp.isFinite &&
          exp * 1000 > now.millisecondsSinceEpoch;
    } catch (_) {
      return false;
    }
  }

  bool get isValid => validAt(DateTime.now());
  factory Session.fromJson(Map<String, dynamic> json) {
    final u = json['usuario'];
    if (u is! Map ||
        json['accessToken'] is! String ||
        (json['accessToken'] as String).trim().isEmpty ||
        u['id'] is! int ||
        u['id'] <= 0 ||
        u['idCentro'] is! int ||
        u['idCentro'] <= 0 ||
        u['nombre'] is! String ||
        (u['nombre'] as String).trim().isEmpty ||
        u['centro'] is! String ||
        (u['centro'] as String).trim().isEmpty) {
      throw const AppFailure(
        'La respuesta de acceso no coincide con el contrato acordado.',
      );
    }
    if (u['rol'] != 'OPERARIO') {
      throw const AppFailure(
        'Esta aplicación requiere una cuenta de operario.',
      );
    }
    return Session(
      token: json['accessToken'],
      name: u['nombre'],
      centerName: u['centro'],
      userId: u['id'],
      centerId: u['idCentro'],
    );
  }
  Map<String, dynamic> toJson() => {
    'accessToken': token,
    'usuario': {
      'id': userId,
      'nombre': name,
      'rol': 'OPERARIO',
      'idCentro': centerId,
      'centro': centerName,
    },
  };
}
