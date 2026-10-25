import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../models/catalog.dart';
import '../models/session.dart';
import 'widgets.dart';
import 'components/catalog_picker.dart';
import 'components/primary_button.dart';
import 'capture/origin_step.dart';
import 'capture/measurements_step.dart';
import 'capture/review_step.dart';
import 'local_detail_view.dart';

class CaptureView extends ConsumerStatefulWidget {
  final Session session;
  const CaptureView({super.key, required this.session});
  @override
  ConsumerState<CaptureView> createState() => _CaptureState();
}

class _CaptureState extends ConsumerState<CaptureView> {
  int step = 0;

  Future<void> select(String type, List<CatalogItem> items) async {
    final item = await showModalBottomSheet<CatalogItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CatalogPicker(
        title: type == 'proveedor'
            ? 'Seleccionar Proveedor'
            : 'Seleccionar Vehículo',
        items: items,
      ),
    );
    if (item != null && mounted) {
      ref.read(workspaceProvider(widget.session)).select(type, item);
    }
  }

  Future<void> next() async {
    final vm = ref.read(workspaceProvider(widget.session));
    FocusScope.of(context).unfocus();
    if (step < 2) {
      if (vm.validate(originOnly: step == 0)) {
        setState(() => step++);
      }
      return;
    }
    final lot = await vm.capture();
    if (lot != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LocalDetailView(session: widget.session, lot: lot),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(workspaceProvider(widget.session));

    return PopScope(
      canPop: !vm.busy && step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !vm.busy && step > 0) {
          setState(() => step--);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Nueva Recepción')),
        body: SafeArea(
          child: PageBody(
            children: [
              SectionCard(
                children: [
                  Text(
                    'Paso ${step + 1} de 3 · ${['Origen', 'Mediciones', 'Revisión'][step]}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: (step + 1) / 3),
                ],
              ),

              // Auto-save Edition Bar
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_done_outlined,
                      size: 16,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.editionState,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reintentar guardado de edición',
                      onPressed: vm.busy ? null : vm.ensureEdition,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              if (vm.error != null) Notice(vm.error!, error: true),

              // PASO 1: ORIGEN
              if (step == 0)
                CaptureOriginStep(
                  vm: vm,
                  session: widget.session,
                  onSelect: select,
                ),

              // PASO 2: MEDICIONES
              if (step == 1)
                CaptureMeasurementsStep(vm: vm, session: widget.session),

              // PASO 3: REVISIÓN
              if (step == 2) CaptureReviewStep(vm: vm, session: widget.session),

              // Botones de Acción
              PrimaryButton(
                key: const Key('capture-next'),
                onPressed: vm.busy || !vm.ready ? null : next,
                label: vm.busy
                    ? 'Guardando…'
                    : step == 2
                    ? 'Guardar recepción'
                    : 'Continuar',
              ),
              if (step > 0) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: vm.busy ? null : () => setState(() => step--),
                  child: const Text('Volver al paso anterior'),
                ),
              ],
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.rejectedText,
                ),
                onPressed: vm.busy
                    ? null
                    : () async {
                        if (await confirmAction(
                          context,
                          'Descartar edición',
                          'Solo se borrarán los campos actuales. Las recepciones guardadas se conservan.',
                          action: 'Descartar',
                        )) {
                          await vm.discard();
                          if (mounted) {
                            setState(() => step = 0);
                          }
                        }
                      },
                child: const Text('Descartar recepción en edición'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
