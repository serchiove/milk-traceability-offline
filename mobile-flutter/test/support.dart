import 'dart:convert';
import 'package:acopio_flutter/models/session.dart';
import 'package:acopio_flutter/models/catalog.dart';
import 'package:acopio_flutter/services/session_service.dart';
import 'package:http/http.dart' as http;

Session session({int user = 1, int center = 2, int? expiry}) => Session(
  token:
      'header.${base64Url.encode(utf8.encode(jsonEncode({'exp': expiry ?? DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600}))).replaceAll('=', '')}.signature',
  name: 'Operario de prueba',
  centerName: 'Centro Majes',
  userId: user,
  centerId: center,
);
Map<String, String> validForm() => {
  'proveedor': "Fundo O'Connor",
  'vehiculo': 'abc-123',
  'centro': 'Centro Majes',
  'idProveedor': '3',
  'idVehiculo': '4',
  'volumen': '120,50',
  'temperatura': '4.5',
  'acidez': '16',
  'densidad': '1,0300',
};
Map<String, dynamic> result(
  String id, {
  bool replay = false,
  String state = 'APROBADO',
}) => {
  'idLote': id,
  'estadoEvaluacion': state,
  'motivo': state == 'RECHAZADO' ? 'Regla demo' : null,
  'codigoQr': state == 'APROBADO' ? 'ACOPIO:$id' : null,
  'versionReglas': 'DEMO-1',
  'recibidoEn': '2026-10-24T12:00:00Z',
  'idempotente': replay,
};
final supplier = {
  'id': 3,
  'razonSocial': "Fundo O'Connor",
  'tipoDocumento': 'RUC',
  'numeroDocumento': '20123456789',
  'estadoCert': 'VIGENTE',
};
final vehicle = {'id': 4, 'placa': 'ABC-123', 'capacidadLitros': 5000};
final center = {
  'id': 2,
  'nombre': 'Centro Majes',
  'region': 'Arequipa',
  'capacidadLitros': 10000,
};
CatalogCache cache() => CatalogCache(
  [CatalogItem.parse(supplier, 'proveedores')],
  [CatalogItem.parse(vehicle, 'vehiculos')],
  center,
  '2026-10-24T12:00:00Z',
);
http.Response response(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

class MemorySessionStore implements SessionStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}
