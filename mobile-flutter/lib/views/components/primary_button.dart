import 'package:flutter/material.dart';

/// Acción principal. El color y la altura provienen de core/theme.dart.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final ButtonStyle? style;
  final VoidCallback? onPressed;
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.style,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: icon == null
        ? FilledButton(
            style: style,
            onPressed: onPressed,
            child: Text(label, textAlign: TextAlign.center),
          )
        : FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, textAlign: TextAlign.center),
          ),
  );
}
