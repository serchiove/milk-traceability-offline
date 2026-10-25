import 'package:flutter/material.dart';
import '../../core/theme.dart';

class Notice extends StatelessWidget {
  final String message;
  final bool error;
  final bool warning;
  final IconData? icon;

  const Notice(
    this.message, {
    super.key,
    this.error = false,
    this.warning = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor, borderColor, defaultIcon) = error
        ? (
            AppColors.rejectedText,
            AppColors.rejectedContainer,
            AppColors.rejectedBorder,
            Icons.error_outline_rounded,
          )
        : warning
        ? (
            AppColors.pendingText,
            AppColors.pendingContainer,
            AppColors.pendingBorder,
            Icons.warning_amber_rounded,
          )
        : (
            AppColors.primaryContainer,
            AppColors.surfaceContainerLow,
            AppColors.border,
            Icons.info_outline_rounded,
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? defaultIcon, size: 20, color: textColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
