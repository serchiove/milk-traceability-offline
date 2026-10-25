import 'package:flutter/material.dart';
import '../../core/theme.dart';

class Metrics extends StatelessWidget {
  final List<(String, String)> values;
  const Metrics(this.values, {super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns =
          c.maxWidth >= 340 && MediaQuery.textScalerOf(context).scale(1) <= 1.3
          ? 2
          : 1;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: values
            .map(
              (v) => SizedBox(
                width: (c.maxWidth - 10 * (columns - 1)) / columns,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.$1.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v.$2,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryContainer,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}
