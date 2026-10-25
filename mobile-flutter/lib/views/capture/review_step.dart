import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/session.dart';
import '../../viewmodels/workspace_view_model.dart';
import '../widgets.dart';
import 'reception_fields.dart';

/// Presentación del paso 3 de recepción. Las reglas permanecen en el ViewModel.
class CaptureReviewStep extends StatelessWidget {
  final WorkspaceViewModel vm;
  final Session session;
  const CaptureReviewStep({super.key, required this.vm, required this.session});
  @override
  Widget build(BuildContext context) => SectionCard(
    children: [
      Row(
        children: const [
          Icon(
            Icons.fact_check_rounded,
            size: 22,
            color: AppColors.primaryContainer,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '3. Revisión de Recepción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),

      // Resumen de Origen
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROVEEDOR SELECCIONADO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              vm.form['proveedor']!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehículo: ${vm.form['vehiculo']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Centro: ${session.centerName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Grid de Mediciones
      Metrics(
        receptionFields.map((f) => (f.$2, '${vm.form[f.$1]} ${f.$3}')).toList(),
      ),
      const SizedBox(height: 14),

      const Notice(
        'Se guardará localmente. El envío y la evaluación se confirman por separado.',
      ),
    ],
  );
}
