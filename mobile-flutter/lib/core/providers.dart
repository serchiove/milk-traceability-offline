import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/session.dart';
import '../repositories/local_repository.dart';
import '../services/api_client.dart';
import '../services/session_service.dart';
import '../services/sync_service.dart';
import '../services/central_service.dart';
import '../viewmodels/app_viewmodels.dart';
import '../viewmodels/connection_viewmodel.dart';

final apiProvider = Provider<ApiClient>((ref) {
  final api = ApiClient();
  ref.onDispose(api.close);
  return api;
});
final localProvider = Provider<LocalRepository>((ref) {
  final local = LocalRepository();
  ref.onDispose(local.close);
  return local;
});
final connectionProvider = ChangeNotifierProvider(
  (ref) => ConnectionViewModel(ref.watch(apiProvider)),
);
final storeProvider = Provider<SessionStore>((ref) => SecureSessionStore());
final sessionServiceProvider = Provider(
  (ref) => SessionService(
    ref.watch(apiProvider),
    ref.watch(localProvider),
    ref.watch(storeProvider),
  ),
);
final syncProvider = Provider(
  (ref) => SyncService(ref.watch(apiProvider), ref.watch(localProvider)),
);
final centralServiceProvider = Provider(
  (ref) => CentralService(ref.watch(apiProvider)),
);
final authProvider = ChangeNotifierProvider(
  (ref) => AuthViewModel(ref.watch(sessionServiceProvider))..restore(),
);
final workspaceProvider = ChangeNotifierProvider.autoDispose
    .family<WorkspaceViewModel, Session>(
      (ref, s) => WorkspaceViewModel(
        s,
        ref.watch(localProvider),
        ref.watch(sessionServiceProvider),
        ref.watch(syncProvider),
      )..initialize(),
    );
