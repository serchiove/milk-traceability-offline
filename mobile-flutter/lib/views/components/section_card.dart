import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/design_tokens.dart';

class SectionCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderSide? border;

  const SectionCard({
    super.key,
    required this.children,
    this.padding,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: padding ?? const EdgeInsets.all(AppSpacing.card),
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: border?.color ?? AppColors.border,
        width: border?.width ?? 1.0,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(15, 23, 42, 0.04),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}
