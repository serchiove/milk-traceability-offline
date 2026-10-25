import 'package:flutter/material.dart';
import '../models/lot.dart';
import '../models/session.dart';
import '../viewmodels/workspace_view_model.dart';
import 'widgets.dart';
import 'components/section_intro.dart';
import '../core/app_colors.dart';
import 'components/primary_button.dart';
import 'components/local_lot_card.dart';

/// Inicio del operario. Prioriza registrar y resolver envíos pendientes.
class HomeView extends StatelessWidget {
  final Session session;
  final WorkspaceViewModel vm;
  final VoidCallback onCapture, onRecords, onSend;
  final ValueChanged<LocalLot> onOpen;
  const HomeView({
    super.key,
    required this.session,
    required this.vm,
    required this.onCapture,
    required this.onRecords,
    required this.onSend,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionIntro(
        eyebrow: 'ACOPIO / RECEPCIÓN DE LECHE',
        title: 'Hola, ${session.name.split(' ').first}',
        description: session.centerName,
        icon: Icons.water_drop_outlined,
      ),
      PrimaryButton(
        label: 'Nueva recepción',
        icon: Icons.add_rounded,
        onPressed: vm.ready && !vm.busy ? onCapture : null,
      ),
      const SizedBox(height: 16),
      if (vm.form.values.any((value) => value.isNotEmpty))
        const Notice(
          'Tienes una recepción en edición. Nueva recepción permite continuar con los campos guardados.',
        ),
      SectionCard(
        color: vm.pending > 0
            ? AppColors.pendingContainer
            : AppColors.surfaceContainerLowest,
        children: [
          Text(
            '${vm.pending} pendientes de envío',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            vm.pending > 0
                ? 'Están guardados en este celular. Envía cuando el servidor esté disponible.'
                : 'No hay recepciones pendientes de envío.',
          ),
          const SizedBox(height: 12),
          if (vm.pending > 0)
            PrimaryButton(
              label: vm.busy ? 'Enviando…' : 'Enviar pendientes',
              icon: Icons.cloud_upload_outlined,
              onPressed: vm.busy ? null : onSend,
            ),
          TextButton(onPressed: onRecords, child: const Text('Ver registros')),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Últimas recepciones',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      if (vm.lots.isEmpty)
        const Notice(
          'Todavía no hay recepciones guardadas. Comienza con Nueva recepción.',
        ),
      for (final lot in vm.lots.take(3))
        LocalLotCard(lot: lot, onTap: () => onOpen(lot)),
    ],
  );
}
