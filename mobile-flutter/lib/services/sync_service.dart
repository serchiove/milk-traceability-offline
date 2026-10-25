import '../core/config.dart';
import '../models/lot.dart';
import '../models/session.dart';
import '../repositories/local_repository.dart';
import 'api_client.dart';

class SyncService {
  final ApiClient api;
  final LocalRepository local;
  final Map<String, Future<SendResult>> _pending = {};
  SyncService(this.api, this.local);
  Future<SendResult> send(Session session, LotRequest request) {
    final key = '${session.key}:${request.id}';
    return _pending.putIfAbsent(
      key,
      () => _send(session, request).whenComplete(() {
        _pending.remove(key);
      }),
    );
  }

  Future<SendResult> _send(Session s, LotRequest request) async {
    if (!s.isValid) {
      throw const AppFailure(
        'Tu sesión venció. Inicia sesión nuevamente con el mismo operario.',
      );
    }
    final prepared = await local.prepare(request, s);
    if (prepared.result != null) {
      return prepared.result!;
    }
    final raw = await api.request(
      '/api/lotes',
      token: s.token,
      body: {
        ...prepared.request.toJson(),
        'huellaSolicitud': prepared.request.fingerprint(s.userId, s.centerId),
      },
    );
    final result = SendResult.parse(raw, request.id);
    await local.confirm(request.id, result);
    return result;
  }
}
