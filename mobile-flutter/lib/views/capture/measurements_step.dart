import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/session.dart';
import '../../viewmodels/workspace_view_model.dart';
import '../widgets.dart';
import 'reception_fields.dart';

/// Presentación del paso 2 de recepción. Las reglas permanecen en el ViewModel.
class CaptureMeasurementsStep extends StatelessWidget {
  final WorkspaceViewModel vm;
  final Session session;
  const CaptureMeasurementsStep({
    super.key,
    required this.vm,
    required this.session,
  });
  @override
  Widget build(BuildContext context) => SectionCard(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.biotech_rounded, size: 22, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                '2. Mediciones de Plataforma',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.secondaryFixed,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: const Text(
              'EN CURSO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.onSecondaryFixed,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),

      for (final f in receptionFields)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            key: ValueKey('${f.$1}-${vm.formGeneration}'),
            initialValue: vm.form[f.$1],
            enabled: !vm.busy && vm.ready,
            maxLength: 18,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onChanged: (v) => vm.change(f.$1, v),
            decoration: InputDecoration(
              labelText: f.$2,
              suffixText: f.$3,
              hintText: f.$4,
              errorText: vm.errors[f.$1],
              counterText: '',
              prefixIcon: Icon(f.$5, size: 20),
            ),
          ),
        ),

      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: const [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.primaryContainer,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Usa coma o punto decimal. La calidad se evalúa en el servidor después del envío.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
