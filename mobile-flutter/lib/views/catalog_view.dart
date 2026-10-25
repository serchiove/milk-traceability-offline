import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/theme.dart';
import '../models/session.dart';
import '../viewmodels/app_viewmodels.dart';
import 'widgets.dart';

class CatalogView extends ConsumerStatefulWidget {
  final Session session;
  const CatalogView({super.key, required this.session});
  @override
  ConsumerState<CatalogView> createState() => _CatalogState();
}

class _CatalogState extends ConsumerState<CatalogView> {
  late final CatalogViewModel vm;
  final search = TextEditingController();
  bool offline = false;

  @override
  void initState() {
    super.initState();
    vm = CatalogViewModel(widget.session, ref.read(sessionServiceProvider))
      ..load();
  }

  @override
  void dispose() {
    vm.dispose();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider(widget.session));
    final cache = workspace.catalogs;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final cached = vm.type == 'proveedores'
            ? cache?.suppliers
            : cache?.vehicles;
        final items = offline
            ? (cached ?? [])
                  .where(
                    (v) => '${v.label} ${v.description}'.toLowerCase().contains(
                      search.text.toLowerCase(),
                    ),
                  )
                  .toList()
            : vm.data?.items ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('Catálogos')),
          body: SafeArea(
            child: PageBody(
              children: [
                // Info Center Card
                SectionCard(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.factory_outlined,
                            size: 20,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.session.centerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              if (cache != null)
                                Text(
                                  '${cache.center['region']} · Capacidad nominal: ${number(cache.center['capacidadLitros'])} L',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SectionCard(
                  children: [
                    Text(
                      cache == null
                          ? 'Sin copia descargada'
                          : 'Última descarga: ${dateLabel(cache.updated)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: workspace.busy
                          ? null
                          : () async {
                              final updated = await workspace.refreshCatalogs();
                              if (!mounted) return;
                              if (updated) {
                                await vm.load(search: search.text.trim());
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Catálogos actualizados para nuevas capturas. Revisa las selecciones de tu borrador.',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.download_rounded),
                      label: Text(
                        workspace.busy
                            ? 'Actualizando…'
                            : 'Actualizar catálogos',
                      ),
                    ),
                    if (workspace.error != null)
                      Notice(workspace.error!, error: true),
                    const Text(
                      'La actualización conserva tu borrador y los registros guardados. Si falla, puedes seguir usando la copia anterior.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                // Offline copy toggle
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SwitchListTile(
                    activeTrackColor: AppColors.primaryContainer,
                    title: const Text(
                      'Consultar copia descargada',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Disponible en este dispositivo sin conexión a red',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    value: offline,
                    onChanged: (v) => setState(() => offline = v),
                  ),
                ),

                // Type Segmented Button
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'proveedores',
                      label: Text('Proveedores'),
                      icon: Icon(Icons.agriculture_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: 'vehiculos',
                      label: Text('Vehículos'),
                      icon: Icon(Icons.local_shipping_rounded, size: 18),
                    ),
                  ],
                  selected: {vm.type},
                  onSelectionChanged: (s) {
                    search.clear();
                    vm.load(type: s.first, search: '');
                  },
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: search,
                  maxLength: 180,
                  onChanged: (_) {
                    if (offline) {
                      setState(() {});
                    }
                  },
                  onSubmitted: (_) => vm.load(search: search.text.trim()),
                  decoration: InputDecoration(
                    labelText: 'Nombre, documento o placa...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    counterText: '',
                    suffixIcon: search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              search.clear();
                              if (offline) {
                                setState(() {});
                              } else {
                                vm.load(search: '');
                              }
                            },
                          )
                        : null,
                  ),
                ),
                if (!offline) ...[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: vm.busy
                        ? null
                        : () => vm.load(search: search.text.trim()),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Buscar en catálogo'),
                  ),
                ],
                const SizedBox(height: 14),

                if (vm.busy && !offline) const LinearProgressIndicator(),
                if (vm.error != null && !offline)
                  Notice(vm.error!, error: true),

                if (offline && cache != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Descargado: ${dateLabel(cache.updated)} · ${items.length} items en cache',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),

                if (items.isEmpty && !vm.busy)
                  const Notice('No hay coincidencias en el catálogo.'),

                ...items.map(
                  (i) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          vm.type == 'proveedores'
                              ? Icons.agriculture_rounded
                              : Icons.local_shipping_rounded,
                          size: 20,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      title: Text(
                        i.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        i.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),

                if (!offline && vm.data != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Paging(
                      page: vm.data!.page,
                      total: vm.data!.total,
                      size: vm.data!.size,
                      busy: vm.busy,
                      go: (p) => vm.load(page: p),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
