import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../core/config.dart';

const originFields = ['proveedor', 'vehiculo', 'centro'];
const measureFields = ['volumen', 'temperatura', 'acidez', 'densidad'];
Map<String, String> emptyForm() => {
  for (final k in [...originFields, ...measureFields]) k: '',
};
Map<String, String> validateLot(Map<String, String> f) {
  final errors = <String, String>{};
  for (final k in originFields) {
    final v = (f[k] ?? '').trim();
    if (v.isEmpty) {
      errors[k] = 'Completa este campo.';
    } else if (v.length > 180) {
      errors[k] = 'Usa como máximo 180 caracteres.';
    }
  }
  final bounds = {
    'volumen': [0.0, 9999999999.99],
    'temperatura': [-273.15, 9999.99],
    'acidez': [0.0, 9999.99],
    'densidad': [0.0, 999.9999],
  };
  for (final k in measureFields) {
    final raw = (f[k] ?? '').trim().replaceFirst(',', '.');
    final v = double.tryParse(raw);
    if (!RegExp(r'^-?\d+(?:\.\d+)?$').hasMatch(raw) ||
        v == null ||
        !v.isFinite) {
      errors[k] = 'Ingresa un número válido, sin separadores de miles.';
      continue;
    }
    final b = bounds[k]!;
    if (v < b[0] ||
        v > b[1] ||
        ((k == 'volumen' || k == 'densidad') && v == 0)) {
      errors[k] = 'Valor fuera del límite numérico del modelo.';
    }
    final decimals = k == 'densidad' ? 4 : 2;
    if (!errors.containsKey(k) &&
        raw.contains('.') &&
        raw.split('.')[1].length > decimals) {
      errors[k] = 'Usa como máximo $decimals decimales.';
    }
  }
  return errors;
}

class LotRequest {
  final String id, date;
  final int supplierId, vehicleId;
  final double volume, temperature, acidity, density;
  const LotRequest({
    required this.id,
    required this.date,
    required this.supplierId,
    required this.vehicleId,
    required this.volume,
    required this.temperature,
    required this.acidity,
    required this.density,
  });
  factory LotRequest.fromJson(Map<String, dynamic> j) => LotRequest(
    id: j['idLote'],
    date: j['fechaHora'],
    supplierId: j['idProveedor'],
    vehicleId: j['idVehiculo'],
    volume: (j['volumenLitros'] as num).toDouble(),
    temperature: (j['mediciones']['temperaturaC'] as num).toDouble(),
    acidity: (j['mediciones']['acidezDornic'] as num).toDouble(),
    density: (j['mediciones']['densidadGml'] as num).toDouble(),
  );
  Map<String, dynamic> toJson() => {
    'idLote': id,
    'idProveedor': supplierId,
    'idVehiculo': vehicleId,
    'fechaHora': date,
    'volumenLitros': volume,
    'mediciones': {
      'temperaturaC': temperature,
      'acidezDornic': acidity,
      'densidadGml': density,
    },
  };
  // Same field order, UTC milliseconds and stripped decimals as the Java backend.
  String canonical(int user, int center) {
    final instant = DateTime.parse(date).toUtc();
    final millis = DateTime.fromMillisecondsSinceEpoch(
      instant.millisecondsSinceEpoch,
      isUtc: true,
    ).toIso8601String().replaceFirst('.000Z', 'Z');
    String decimal(double n) =>
        n == n.truncateToDouble() ? n.toInt().toString() : n.toString();
    return [
      id,
      supplierId,
      vehicleId,
      user,
      center,
      millis,
      decimal(volume),
      decimal(temperature),
      decimal(acidity),
      decimal(density),
    ].join('|');
  }

  String fingerprint(int user, int center) =>
      sha256.convert(utf8.encode(canonical(user, center))).toString();
}

class SendResult {
  final Map<String, dynamic> json;
  SendResult._(this.json);
  factory SendResult.parse(Map<String, dynamic> j, String expectedId) {
    if (j['idLote'] != expectedId ||
        ![
          'APROBADO',
          'RECHAZADO',
          'PENDIENTE',
        ].contains(j['estadoEvaluacion']) ||
        j['idempotente'] is! bool ||
        j['recibidoEn'] is! String ||
        DateTime.tryParse(j['recibidoEn']) == null ||
        [
          'motivo',
          'codigoQr',
          'versionReglas',
        ].any((k) => j[k] != null && j[k] is! String)) {
      throw const AppFailure(
        'Respuesta no válida. Reintenta con el mismo registro.',
      );
    }
    return SendResult._(Map.unmodifiable(j));
  }
  String get state => json['estadoEvaluacion'];
  String? get qr => json['codigoQr'];
}

class LocalLot {
  final String id, date, supplier, vehicle, center;
  final double volume, temperature, acidity, density;
  final bool sent;
  LocalLot.fromRow(Map<String, Object?> r)
    : id = r['id'] as String,
      date = r['fecha'] as String,
      supplier = r['proveedor'] as String,
      vehicle = r['vehiculo'] as String,
      center = r['centro'] as String,
      volume = (r['volumen'] as num).toDouble(),
      temperature = (r['temperatura'] as num).toDouble(),
      acidity = (r['acidez'] as num).toDouble(),
      density = (r['densidad'] as num).toDouble(),
      sent = r['enviado'] == 1;
}

class PreparedSend {
  final LotRequest request;
  final int user, center;
  final SendResult? result;
  const PreparedSend(this.request, this.user, this.center, this.result);
  factory PreparedSend.fromRow(Map<String, Object?> r) {
    final req = LotRequest.fromJson(jsonDecode(r['solicitud'] as String));
    return PreparedSend(
      req,
      r['usuario'] as int,
      r['centro'] as int,
      r['resultado'] == null
          ? null
          : SendResult.parse(jsonDecode(r['resultado'] as String), req.id),
    );
  }
}
