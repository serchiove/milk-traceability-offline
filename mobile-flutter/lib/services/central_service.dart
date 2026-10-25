import '../core/config.dart';
import '../models/catalog.dart';
import '../models/session.dart';
import 'api_client.dart';

class CentralService {
  final ApiClient api;
  CentralService(this.api);
  Future<ApiPage<Map<String, dynamic>>> lots(
    Session s, {
    int page = 0,
    bool approved = false,
  }) async => ApiPage.parse(
    await api.request(
      '/api/lotes?pagina=$page&tamano=25${approved ? '&estado=APROBADO' : ''}',
      token: s.token,
    ),
    (j) => j,
  );
  Future<Map<String, dynamic>> detail(Session s, String code) async {
    final value = code.trim();
    if (!RegExp(
      r'^(ACOPIO:)?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value)) {
      throw const AppFailure('Ingresa un UUID válido o un QR ACOPIO.');
    }
    return api.request(
      value.startsWith('ACOPIO:')
          ? '/api/lotes/por-qr?codigo=${Uri.encodeQueryComponent(value)}'
          : '/api/lotes/$value',
      token: s.token,
    );
  }

  Future<ApiPage<Map<String, dynamic>>> tanks(
    Session s, {
    int page = 0,
  }) async => ApiPage.parse(
    await api.request(
      '/api/tanques?disponibles=true&pagina=$page&tamano=25',
      token: s.token,
    ),
    (j) => j,
  );
  Future<Map<String, dynamic>> assign(Session s, String id, int tankId) async {
    // Required before every attempt, including retries after an uncertain response.
    final current = await detail(s, id);
    if (current['idTanque'] != null) {
      return current;
    }
    await api.request(
      '/api/lotes/$id/asignacion-tanque',
      token: s.token,
      body: {'idTanque': tankId},
    );
    return detail(s, id);
  }
}
