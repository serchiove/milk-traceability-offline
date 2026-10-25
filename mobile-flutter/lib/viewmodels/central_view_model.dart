import '../models/session.dart';
import '../models/catalog.dart';
import '../services/central_service.dart';
import 'view_model.dart';

/// Consulta lotes y asigna tanques mediante la API.
class CentralViewModel extends ViewModel {
  final Session session;
  final CentralService service;
  final bool approvedOnly;
  ApiPage<Map<String, dynamic>>? list, tanks;
  Map<String, dynamic>? detail;
  String code = '';
  int page = 0, sequence = 0;
  bool assigning = false;
  DateTime? updatedAt;
  CentralViewModel(this.session, this.service, {this.approvedOnly = false});
  Future<void> load([int p = 0]) async {
    if (assigning) {
      return;
    }
    final serial = ++sequence;
    busy = true;
    error = null;
    detail = null;
    tanks = null;
    emit();
    try {
      final data = await service.lots(session, page: p, approved: approvedOnly);
      if (serial == sequence) {
        list = data;
        page = p;
        updatedAt = DateTime.now();
      }
    } catch (e) {
      if (serial == sequence) {
        error = e.toString();
      }
    } finally {
      if (serial == sequence) {
        busy = false;
        emit();
      }
    }
  }

  Future<void> open(String value) async {
    if (assigning) {
      return;
    }
    final serial = ++sequence;
    code = value;
    busy = true;
    error = null;
    detail = null;
    tanks = null;
    emit();
    try {
      final d = await service.detail(session, value);
      if (serial == sequence) {
        detail = d;
        updatedAt = DateTime.now();
      }
    } catch (e) {
      if (serial == sequence) {
        error = e.toString();
      }
    } finally {
      if (serial == sequence) {
        busy = false;
        emit();
      }
    }
  }

  Future<void> loadTanks([int page = 0]) async {
    if (busy) {
      return;
    }
    busy = true;
    error = null;
    tanks = null;
    emit();
    try {
      tanks = await service.tanks(session, page: page);
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      emit();
    }
  }

  Future<void> assign(int id) async {
    if (busy || detail == null) {
      return;
    }
    final lotId = detail!['idLote'] as String;
    assigning = true;
    busy = true;
    error = null;
    tanks = null;
    emit();
    try {
      detail = await service.assign(session, lotId, id);
      updatedAt = DateTime.now();
    } catch (e) {
      detail = null;
      code = lotId;
      error = '$e Consulta nuevamente el lote para conocer su destino.';
    } finally {
      assigning = false;
      busy = false;
      emit();
    }
  }
}
