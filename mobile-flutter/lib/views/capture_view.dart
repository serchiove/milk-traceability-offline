import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../models/catalog.dart';
import '../models/session.dart';
import 'widgets.dart';
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
    const fields = [
      ('volumen', 'Volumen de leche', 'L', '120,50', Icons.scale_rounded),
      (
        'temperatura',
        'Temperatura de recepción',
        '°C',
        '4,5',
        Icons.thermostat_rounded,
      ),
      ('acidez', 'Acidez Dornic', '°D', '16', Icons.science_rounded),
      ('densidad', 'Densidad', 'g/mL', '1,0300', Icons.opacity_rounded),
    ];

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
              // Stepper de 3 pasos (Google Stitch Design System)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Paso ${step + 1} de 3 · ${['Origen', 'Mediciones', 'Revisión'][step]}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _stepNode(0, '1. Origen', step >= 0, step > 0),
                        Expanded(
                          child: Container(
                            height: 3,
                            color: step >= 1
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerHigh,
                          ),
                        ),
                        _stepNode(1, '2. Mediciones', step >= 1, step > 1),
                        Expanded(
                          child: Container(
                            height: 3,
                            color: step >= 2
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerHigh,
                          ),
                        ),
                        _stepNode(2, '3. Guardado', step >= 2, false),
                      ],
                    ),
                  ],
                ),
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
              if (step == 0) ...[
                SectionCard(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 20,
                              color: AppColors.primaryContainer,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '1. Datos de Origen',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text(
                            'EN PROCESO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Centro Asignado (Fijado)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: AppColors.outline,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Centro fijado por turno',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  widget.session.centerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.factory_outlined,
                            size: 20,
                            color: AppColors.outline,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selector de Proveedor
                    OutlinedButton(
                      key: const Key('select-supplier'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: vm.form['proveedor']!.isNotEmpty
                            ? AppColors.surfaceContainerLow
                            : Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: vm.busy || vm.catalogs == null
                          ? null
                          : () => select('proveedor', vm.catalogs!.suppliers),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.agriculture_rounded,
                              size: 20,
                              color: AppColors.onSecondaryFixed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Proveedor ganadero',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  vm.form['proveedor']!.isEmpty
                                      ? 'Seleccionar proveedor'
                                      : vm.form['proveedor']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: vm.form['proveedor']!.isEmpty
                                        ? AppColors.outline
                                        : AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.outline,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selector de Vehículo
                    OutlinedButton(
                      key: const Key('select-vehicle'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: vm.form['vehiculo']!.isNotEmpty
                            ? AppColors.surfaceContainerLow
                            : Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: vm.busy || vm.catalogs == null
                          ? null
                          : () => select('vehiculo', vm.catalogs!.vehicles),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              size: 20,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cisterna o vehículo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  vm.form['vehiculo']!.isEmpty
                                      ? 'Seleccionar vehículo'
                                      : vm.form['vehiculo']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: vm.form['vehiculo']!.isEmpty
                                        ? AppColors.outline
                                        : AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.outline,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Catálogo descargado: ${vm.catalogs == null ? 'No disponible' : dateLabel(vm.catalogs!.updated)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ],

              // PASO 2: MEDICIONES
              if (step == 1) ...[
                SectionCard(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.biotech_rounded,
                              size: 22,
                              color: AppColors.secondary,
                            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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

                    for (final f in fields)
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
                ),
              ],

              // PASO 3: REVISIÓN
              if (step == 2) ...[
                SectionCard(
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
                                'Centro: ${widget.session.centerName}',
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
                      fields
                          .map((f) => (f.$2, '${vm.form[f.$1]} ${f.$3}'))
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    const Notice(
                      'Se guardará localmente. El envío y la evaluación se confirman por separado.',
                    ),
                  ],
                ),
              ],

              // Botones de Acción
              FilledButton(
                key: const Key('capture-next'),
                onPressed: vm.busy || !vm.ready ? null : next,
                child: Text(
                  vm.busy
                      ? 'Guardando…'
                      : step == 2
                      ? 'Guardar recepción'
                      : 'Continuar',
                ),
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

  Widget _stepNode(int index, String label, bool active, bool completed) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: completed || (active && index == step)
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: completed
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    ],
  );
}

class CatalogPicker extends StatefulWidget {
  final String title;
  final List<CatalogItem> items;
  const CatalogPicker({super.key, required this.title, required this.items});
  @override
  State<CatalogPicker> createState() => _PickerState();
}

class _PickerState extends State<CatalogPicker> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final items = widget.items
        .where(
          (i) => '${i.label} ${i.description}'.toLowerCase().contains(
            search.toLowerCase(),
          ),
        )
        .toList();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      height: MediaQuery.sizeOf(context).height * .8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar catálogo',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: const InputDecoration(
                labelText: 'Buscar en catálogo',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay coincidencias en el catálogo descargado.',
                        style: TextStyle(color: AppColors.outline),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, i) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        title: Text(
                          items[i].label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          items[i].description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.outline,
                        ),
                        onTap: () => Navigator.pop(context, items[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
