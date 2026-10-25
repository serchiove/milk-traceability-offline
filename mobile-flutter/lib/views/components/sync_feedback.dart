import 'package:flutter/material.dart';
import '../../models/sync_summary.dart';
import '../widgets.dart';

/// Resultado del último envío conjunto, incluidos errores parciales.
class SyncFeedback extends StatelessWidget {
  final SyncSummary summary;
  final VoidCallback? onRetry;
  const SyncFeedback({super.key, required this.summary, this.onRetry});
  @override
  Widget build(BuildContext context) => SectionCard(
    children: [
      Text(
        'Resultado del último envío',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Notice(summary.message, warning: summary.failures.isNotEmpty),
      const Text(
        'Recibido confirma el envío. Aprobado o rechazado corresponde a la evaluación de calidad.',
      ),
      Text('Finalizado: ${dateLabel(summary.finishedAt.toIso8601String())}'),
      for (final failure in summary.failures.entries)
        Text('Lote ${failure.key}: ${failure.value}'),
      if (summary.failures.isNotEmpty)
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('Reintentar pendientes'),
        ),
    ],
  );
}
