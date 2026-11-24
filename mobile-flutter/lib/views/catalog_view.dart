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
  String type = 'proveedores';

  void searchOnline() {
    if (!offline && !vm.busy) {
      vm.load(type: type, search: search.text.trim());
    }
  }

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
        final cached = type == 'proveedores'
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
                Text(
                  widget.session.centerName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
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
                                if (!offline) {
                                  await vm.load(
                                    type: type,
                                    search: search.text.trim(),
                                  );
                                }
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Copia descargada actualizada.',
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
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Consultar copia descargada'),
                        value: offline,
                        onChanged: cache == null
                            ? null
                            : (value) {
                                setState(() => offline = value);
                                if (!value) {
                                  vm.load(
                                    type: type,
                                    search: search.text.trim(),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
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
                  selected: {type},
                  onSelectionChanged: (s) {
                    search.clear();
                    setState(() => type = s.first);
                    if (!offline) vm.load(type: type, search: '');
                  },
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: search,
                  maxLength: 180,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => searchOnline(),
                  decoration: InputDecoration(
                    labelText: type == 'proveedores'
                        ? 'Buscar por nombre o documento'
                        : 'Buscar por placa o descripción',
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
                    onPressed: vm.busy ? null : searchOnline,
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Buscar en catálogo'),
                  ),
                ],
                const SizedBox(height: 14),

                if (vm.busy && !offline) const LinearProgressIndicator(),
                if (vm.error != null && !offline)
                  Notice(vm.error!, error: true),

                if (offline)
                  Text(
                    '${items.length} resultados en la copia descargada',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (items.isEmpty &&
                    (offline || (!vm.busy && vm.error == null)))
                  const Notice('No hay coincidencias en el catálogo.'),

                ...items.map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.border),
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
                            type == 'proveedores'
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
