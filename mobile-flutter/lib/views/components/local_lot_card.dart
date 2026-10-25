import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/lot.dart';
import '../widgets.dart';

/// Resumen de una recepción de este celular. No consulta ni modifica datos.
class LocalLotCard extends StatelessWidget {
  final LocalLot lot;
  final VoidCallback onTap;
  const LocalLotCard({super.key, required this.lot, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lot.supplier,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${lot.vehicle} · ${dateLabel(lot.date)}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${number(lot.volume)} L',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                StateBadge(
                  lot.sent ? 'RECIBIDO POR SERVIDOR' : 'PENDIENTE DE ENVÍO',
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
