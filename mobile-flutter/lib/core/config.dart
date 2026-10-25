class AppConfig {
  static const apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:18080',
  );
  static const authPath = String.fromEnvironment(
    'AUTH_PATH',
    defaultValue: '/api/auth/login',
  );
}

class AppFailure implements Exception {
  final String message;
  final int? status;
  const AppFailure(this.message, [this.status]);
  @override
  String toString() => message;
}
