import 'package:diacritic/diacritic.dart';
import '../core/config.dart';
import '../models/session.dart';
import '../models/catalog.dart';
import '../models/lot.dart';
import '../models/sync_summary.dart';
import '../repositories/local_repository.dart';
import '../services/session_service.dart';
import '../services/sync_service.dart';
import 'view_model.dart';

/// Coordina captura local, borradores, catálogos y envío.
class WorkspaceViewModel extends ViewModel {
  final Session session;
  final LocalRepository local;
  final SessionService sessions;
  final SyncService sync;
  List<LocalLot> lots = [];
  CatalogCache? catalogs;
  Map<String, String> form = emptyForm(), errors = {};
  String editionState = 'Cargando edición…';
  bool ready = false, recovered = false;
  DateTime? localReadAt;
  SyncSummary? lastSync;
  int syncProcessed = 0, syncTotal = 0;
  int revision = 0, formGeneration = 0;
  WorkspaceViewModel(this.session, this.local, this.sessions, this.sync);
  int get pending => lots.where((l) => !l.sent).length;
  double get liters =>
      lots.fold<int>(0, (sum, l) => sum + (l.volume * 100).round()) / 100;
  List<LocalLot> search(String term, {bool pendingOnly = false}) {
    final needle = removeDiacritics(term).toLowerCase().trim();
    return lots
        .where(
          (l) =>
              (!pendingOnly || !l.sent) &&
              [
                l.id,
                l.supplier,
                l.vehicle,
                l.center,
              ].any((v) => removeDiacritics(v).toLowerCase().contains(needle)),
        )
        .toList();
  }

  Future<void> initialize() async {
    busy = true;
    error = null;
    emit();
    try {
      catalogs = await sessions.cached(session);
      final saved = await local.edition(session.key);
      form = saved ?? emptyForm();
      recovered = saved != null;
      ready = true;
      editionState = 'Guardado en el dispositivo';
      lots = await local.lots(session);
      localReadAt = DateTime.now();
    } catch (e) {
      error = 'No se pudo recuperar la información local. $e';
    } finally {
      busy = false;
      emit();
    }
  }

  Future<void> refresh() async {
    try {
      lots = await local.lots(session);
      localReadAt = DateTime.now();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    emit();
  }

  Future<bool> refreshCatalogs() async {
    if (busy || !ready) return false;
    busy = true;
    error = null;
    emit();
    try {
      catalogs = await sessions.refreshCatalogs(session);
      return true;
    } catch (e) {
      error =
          'No se actualizaron los catálogos. Se conserva la copia anterior. $e';
      return false;
    } finally {
      busy = false;
      emit();
    }
  }

  void change(String key, String value) {
    if (!ready || busy) {
      return;
    }
    form = {...form, key: value};
    errors.remove(key);
    recovered = false;
    final version = ++revision;
    editionState = 'Guardando…';
    emit();
    local
        .saveEdition(session.key, form)
        .then((_) {
          if (version == revision) {
            editionState = 'Guardado en el dispositivo';
            emit();
          }
        })
        .catchError((Object e) {
          if (version == revision) {
            editionState = 'No se pudo guardar. Reintenta.';
            error = e.toString();
            emit();
          }
        });
  }

  void select(String type, CatalogItem item) {
    if (!ready || busy) {
      return;
    }
    form = {
      ...form,
      type: item.label,
      type == 'proveedor' ? 'idProveedor' : 'idVehiculo': item.id.toString(),
      'centro': catalogs!.center['nombre'],
    };
    change(type, item.label);
  }

  Future<bool> ensureEdition() async {
    if (busy) {
      await local.flush();
      return ready;
    }
    if (!ready) {
      return false;
    }
    try {
      await local.saveEdition(session.key, form);
      editionState = 'Guardado en el dispositivo';
      emit();
      return true;
    } catch (e) {
      error = 'No se pudo conservar la edición. $e';
      emit();
      return false;
    }
  }

  bool validate({bool originOnly = false}) {
    error = null;
    if (!session.isValid) {
      error =
          'La sesión venció. Inicia sesión nuevamente; la edición se conserva.';
      emit();
      return false;
    }
    if (catalogs == null ||
        !catalogs!.suppliers.any(
          (v) => v.id.toString() == form['idProveedor'],
        ) ||
        !catalogs!.vehicles.any((v) => v.id.toString() == form['idVehiculo'])) {
      error = 'Selecciona proveedor y vehículo del catálogo descargado.';
      emit();
      return false;
    }
    errors = validateLot(form);
    if (originOnly) {
      errors.removeWhere((k, _) => !originFields.contains(k));
    }
    emit();
    return errors.isEmpty;
  }

  Future<LocalLot?> capture() async {
    if (busy || !ready || !validate()) {
      return null;
    }
    busy = true;
    emit();
    try {
      final saved = await local.capture(form, session);
      ++revision;
      form = emptyForm();
      formGeneration++;
      errors = {};
      recovered = false;
      editionState = 'Guardado en el dispositivo';
      lots = await local.lots(session);
      localReadAt = DateTime.now();
      return saved;
    } catch (e) {
      error = 'No se pudo guardar. Tus campos se conservan. $e';
      return null;
    } finally {
      busy = false;
      emit();
    }
  }

  Future<void> discard() async {
    if (busy || !ready) {
      return;
    }
    busy = true;
    emit();
    try {
      await local.saveEdition(session.key, emptyForm());
      ++revision;
      form = emptyForm();
      formGeneration++;
      errors = {};
      recovered = false;
      editionState = 'Guardado en el dispositivo';
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      emit();
    }
  }

  Future<SendResult?> send(LocalLot lot) async {
    if (busy) {
      return null;
    }
    busy = true;
    error = null;
    emit();
    try {
      return await _sendConfirmed(lot);
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      busy = false;
      emit();
    }
  }

  Future<SendResult> _sendConfirmed(LocalLot lot) async {
    final prepared = await local.send(lot.id);
    if (prepared == null) {
      throw const AppFailure(
        'No se pudo leer el envío. Conserva el registro y reintenta.',
      );
    }
    final result = await sync.send(session, prepared.request);
    lots = await local.lots(session);
    localReadAt = DateTime.now();
    return result;
  }

  Future<SyncSummary?> sendAll() async {
    if (busy || !ready) return null;
    final pendingLots = lots.where((lot) => !lot.sent).toList();
    busy = true;
    error = null;
    lastSync = null;
    syncProcessed = 0;
    syncTotal = pendingLots.length;
    var confirmed = 0, approved = 0, rejected = 0;
    final failures = <String, String>{};
    emit();
    try {
      for (final lot in pendingLots) {
        try {
          final result = await _sendConfirmed(lot);
          confirmed++;
          if (result.state == 'APROBADO') approved++;
          if (result.state == 'RECHAZADO') rejected++;
        } catch (e) {
          failures[lot.id] = e.toString();
        }
        syncProcessed++;
        emit();
      }
      lastSync = SyncSummary(
        confirmed: confirmed,
        approved: approved,
        rejected: rejected,
        failures: failures,
      );
      return lastSync;
    } finally {
      syncTotal = 0;
      busy = false;
      emit();
    }
  }
}
