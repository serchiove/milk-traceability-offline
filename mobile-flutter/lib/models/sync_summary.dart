class SyncSummary {
  final int confirmed, approved, rejected;
  final Map<String, String> failures;
  final DateTime finishedAt;

  SyncSummary({
    required this.confirmed,
    required this.approved,
    required this.rejected,
    required Map<String, String> failures,
  }) : failures = Map.unmodifiable(failures),
       finishedAt = DateTime.now();

  String get message =>
      '$confirmed enviados al servidor, ${failures.length} pendientes de reintento. Calidad: $approved aprobados y $rejected rechazados.';
}
