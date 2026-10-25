import '../models/session.dart';
import '../services/session_service.dart';
import 'view_model.dart';

/// Restaura, inicia y cierra la sesión del operario.
class AuthViewModel extends ViewModel {
  final SessionService service;
  Session? session;
  bool booting = true;
  AuthViewModel(this.service);
  Future<void> restore({bool manual = false}) async {
    if (busy) {
      return;
    }
    busy = true;
    error = null;
    emit();
    try {
      await service.local.db;
      session = await service.restore();
      if (manual && session == null) {
        error =
            'Inicia sesión con conexión para autorizar este dispositivo y descargar los catálogos.';
      }
    } catch (e) {
      error = 'No se pudo recuperar el acceso local. Reintenta. $e';
    } finally {
      busy = false;
      booting = false;
      emit();
    }
  }

  Future<void> login(String email, String password) async {
    if (busy) {
      return;
    }
    busy = true;
    error = null;
    emit();
    try {
      session = await service.login(email, password);
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      emit();
    }
  }

  Future<void> logout() async {
    if (busy) {
      return;
    }
    busy = true;
    error = null;
    emit();
    try {
      await service.logout();
      session = null;
    } catch (e) {
      error = 'No se pudo cerrar la sesión. Reintenta. $e';
    } finally {
      busy = false;
      emit();
    }
  }
}
