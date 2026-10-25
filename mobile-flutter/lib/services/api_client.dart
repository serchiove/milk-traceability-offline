import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class ApiClient {
  final http.Client client;
  final String baseUrl;
  final Duration timeout;
  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : client = client ?? http.Client(),
       baseUrl = (baseUrl ?? AppConfig.apiUrl).replaceFirst(RegExp(r'/+$'), '');
  Future<Map<String, dynamic>> request(
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response =
          await (body == null
                  ? client.get(uri, headers: headers)
                  : client.post(uri, headers: headers, body: jsonEncode(body)))
              .timeout(timeout ?? this.timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppFailure(switch (response.statusCode) {
          400 =>
            'El servidor rechazó los datos o el catálogo dejó de estar activo. Conserva el registro para su revisión.',
          401 =>
            'La sesión ya no es válida. Vuelve a iniciar sesión con el mismo operario.',
          403 => 'Tu cuenta no tiene permiso para esta operación.',
          404 => 'No se encontró el registro en tu centro.',
          409 =>
            'El servidor detectó un conflicto. Consulta el estado y conserva el registro original.',
          429 => 'Demasiados intentos. Espera antes de volver a intentar.',
          _ =>
            'No se confirmó la operación. Puedes reintentar con el mismo registro.',
        }, response.statusCode);
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return json;
    } on TimeoutException {
      throw const AppFailure(
        'Se agotó el tiempo. El registro se conserva; reintenta para confirmar si llegó al servidor.',
      );
    } on SocketException {
      throw const AppFailure(
        'No se pudo conectar con el servidor. Tus registros siguen en este celular.',
      );
    } on http.ClientException {
      throw const AppFailure(
        'Se perdió la conexión. El registro se conserva; reintenta con el mismo identificador.',
      );
    } on FormatException {
      throw const AppFailure(
        'El servidor devolvió una respuesta no válida. Reintenta con el mismo registro.',
      );
    }
  }

  void close() => client.close();
}
