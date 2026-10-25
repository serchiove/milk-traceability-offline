import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StateBadge extends StatelessWidget {
  final String state;
  final bool compact;

  const StateBadge(this.state, {super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final norm = state.toUpperCase().trim();
    final (textColor, bgColor, borderColor, iconData) = switch (norm) {
      'APROBADO' || 'APROBADO POR CALIDAD' => (
        AppColors.approvedText,
        AppColors.approvedContainer,
        AppColors.approvedBorder,
        Icons.check_circle_rounded,
      ),
      'RECHAZADO' => (
        AppColors.rejectedText,
        AppColors.rejectedContainer,
        AppColors.rejectedBorder,
        Icons.cancel_rounded,
      ),
      'ENVIADO' || 'RECIBIDO POR SERVIDOR' => (
        AppColors.serverText,
        AppColors.serverContainer,
        AppColors.serverBorder,
        Icons.cloud_done_rounded,
      ),
      'LOCAL' || 'ALMACENAMIENTO LOCAL' => (
        AppColors.localText,
        AppColors.localContainer,
        AppColors.localBorder,
        Icons.smartphone_rounded,
      ),
      _ => (
        AppColors.pendingText,
        AppColors.pendingContainer,
        AppColors.pendingBorder,
        Icons.schedule_rounded,
      ),
    };

    final displayText =
        norm == 'PENDIENTE DE ENVIO' || norm == 'PENDIENTE DE ENVÍO'
        ? 'PENDIENTE DE ENVÍO'
        : norm;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 5,
        children: [
          Icon(iconData, size: compact ? 13 : 15, color: textColor),
          Text(
            displayText,
            style: TextStyle(
              color: textColor,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
