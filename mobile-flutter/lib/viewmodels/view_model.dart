import 'package:flutter/foundation.dart';

/// Estado común de carga y errores.
class ViewModel extends ChangeNotifier {
  bool busy = false, disposed = false;
  String? error;
  void emit() {
    if (!disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
