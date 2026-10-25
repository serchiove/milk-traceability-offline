import '../models/session.dart';
import '../models/catalog.dart';
import '../services/session_service.dart';
import 'view_model.dart';

/// Consulta los catálogos paginados del servidor.
class CatalogViewModel extends ViewModel {
  final Session session;
  final SessionService service;
  ApiPage<CatalogItem>? data;
  String type = 'proveedores', search = '';
  int sequence = 0;
  CatalogViewModel(this.session, this.service);
  Future<void> load({int page = 0, String? type, String? search}) async {
    this.type = type ?? this.type;
    this.search = search ?? this.search;
    final serial = ++sequence;
    busy = true;
    error = null;
    data = null;
    emit();
    try {
      final result = await service.catalog(
        session,
        this.type,
        search: this.search,
        page: page,
      );
      if (serial == sequence) {
        data = result;
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
}
