import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/catalog.dart';

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
