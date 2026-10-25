import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/session.dart';
import '../../models/catalog.dart';
import '../../viewmodels/workspace_view_model.dart';
import '../widgets.dart';

/// Presentación del paso 1 de recepción. Las reglas permanecen en el ViewModel.
class CaptureOriginStep extends StatelessWidget {
  final WorkspaceViewModel vm;
  final Session session;
  final Future<void> Function(String, List<CatalogItem>) onSelect;
  const CaptureOriginStep({
    super.key,
    required this.vm,
    required this.session,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) => SectionCard(
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    session.centerName,
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
            : () => onSelect('proveedor', vm.catalogs!.suppliers),
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
            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.outline),
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
            : () => onSelect('vehiculo', vm.catalogs!.vehicles),
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
            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.outline),
          ],
        ),
      ),
      const SizedBox(height: 14),

      Text(
        'Catálogo descargado: ${vm.catalogs == null ? 'No disponible' : dateLabel(vm.catalogs!.updated)}',
        style: const TextStyle(fontSize: 11, color: AppColors.outline),
      ),
    ],
  );
}
