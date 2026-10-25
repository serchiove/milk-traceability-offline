import 'package:flutter/material.dart';
import '../../core/theme.dart';

class Paging extends StatelessWidget {
  final int page, total, size;
  final bool busy;
  final void Function(int) go;

  const Paging({
    super.key,
    required this.page,
    required this.total,
    required this.size,
    required this.busy,
    required this.go,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$total resultados · Pág. ${page + 1}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Página anterior',
              onPressed: busy || page == 0 ? null : () => go(page - 1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Página siguiente',
              onPressed: busy || (page + 1) * size >= total
                  ? null
                  : () => go(page + 1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    ),
  );
}
