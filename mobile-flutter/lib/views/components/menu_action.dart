import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// Una acción de menú: icono, título, explicación y destino accesible.
/// Expanded permite que el texto crezca sin desbordar en celulares pequeños.
class MenuAction extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  const MenuAction({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.accent = AppColors.secondary,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 5),
                    Text(description),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.outline,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
