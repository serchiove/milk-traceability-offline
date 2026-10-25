import 'package:flutter/material.dart';
import '../models/lot.dart';
import '../viewmodels/workspace_view_model.dart';
import 'widgets.dart';
import 'components/local_lot_card.dart';
import 'components/primary_button.dart';

/// Lista local con búsqueda y filtro. El Shell conserva los filtros entre pestañas.
class RecordsView extends StatelessWidget {
  final WorkspaceViewModel vm;
  final String query;
  final bool pendingOnly;
  final ValueChanged<String> onQuery;
  final ValueChanged<bool> onPending;
  final ValueChanged<LocalLot> onOpen;
  final VoidCallback onSend;
  const RecordsView({
    super.key,
    required this.vm,
    required this.query,
    required this.pendingOnly,
    required this.onQuery,
    required this.onPending,
    required this.onOpen,
    required this.onSend,
  });
  @override
  Widget build(BuildContext context) {
    final lots = vm.search(query, pendingOnly: pendingOnly);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Notice(
          'Registros de este celular y de tu cuenta. Los recibidos también se consultan desde Central.',
        ),
        TextFormField(
          initialValue: query,
          onChanged: onQuery,
          decoration: const InputDecoration(
            labelText: 'Buscar proveedor, placa o UUID',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: !pendingOnly,
              onSelected: (_) => onPending(false),
            ),
            ChoiceChip(
              label: Text('Pendientes (${vm.pending})'),
              selected: pendingOnly,
              onSelected: (_) => onPending(true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (vm.pending > 0) ...[
          PrimaryButton(
            label: 'Enviar pendientes',
            icon: Icons.cloud_upload_outlined,
            onPressed: vm.busy ? null : onSend,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          '${lots.length} registros encontrados',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (lots.isEmpty)
          const Notice(
            'No hay registros para estos filtros. Prueba con Todos o cambia la búsqueda.',
          ),
        for (final lot in lots)
          LocalLotCard(lot: lot, onTap: () => onOpen(lot)),
      ],
    );
  }
}
