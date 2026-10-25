import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

class ConnectionViewModel extends ChangeNotifier {
  final ApiClient api;
  bool checking = false;
  bool? online;
  DateTime? checkedAt;
  String message = 'Conexión sin comprobar';
  bool _disposed = false;

  ConnectionViewModel(this.api);

  String get label => checking
      ? 'Comprobando servidor…'
      : online == true
      ? 'Servidor disponible'
      : online == false
      ? 'Servidor sin conexión'
      : 'Conexión sin comprobar';

  Future<void> check() async {
    if (checking || _disposed) return;
    checking = true;
    notifyListeners();
    try {
      final data = await api.request(
        '/api/estado',
        timeout: const Duration(seconds: 5),
      );
      online = data['estado'] == 'CONECTADO';
      message = online == true
          ? 'Servidor y base de datos disponibles.'
          : 'El servidor no confirmó que la base de datos esté disponible.';
    } catch (_) {
      online = false;
      message =
          'No se pudo consultar el servidor. Puedes trabajar con tu sesión vigente y los catálogos descargados.';
    } finally {
      checkedAt = DateTime.now();
      checking = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
