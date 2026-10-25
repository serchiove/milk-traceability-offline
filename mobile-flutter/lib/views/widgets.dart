import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme.dart';

String number(num n, [int decimals = 2]) => NumberFormat.decimalPatternDigits(
  locale: 'es_PE',
  decimalDigits: decimals,
).format(n);

String dateLabel(String raw) {
  final date = DateTime.tryParse(raw);
  return date == null
      ? raw
      : DateFormat('dd/MM/yyyy HH:mm', 'es_PE').format(date.toLocal());
}

String timeLabel(String raw) {
  final date = DateTime.tryParse(raw);
  return date == null
      ? raw
      : DateFormat('hh:mm a', 'es_PE').format(date.toLocal());
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  const PageBody({super.key, required this.children, this.padding});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: padding ?? const EdgeInsets.fromLTRB(16, 14, 16, 96),
        children: children,
      ),
    ),
  );
}

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
    padding: padding ?? const EdgeInsets.all(18),
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

    final displayText = norm == 'PENDIENTE DE ENVIO' || norm == 'PENDIENTE DE ENVÍO'
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

class LotQr extends StatelessWidget {
  final String code;
  const LotQr(this.code, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8, bottom: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(15, 23, 42, 0.04),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: const [
            Icon(Icons.qr_code_2_rounded, color: AppColors.primaryContainer, size: 22),
            SizedBox(width: 8),
            Text(
              'Certificado QR ACOPIO',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Semantics(
              label: 'Código QR del lote: $code',
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: SelectableText(
            code,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

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

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String text, {
  String action = 'Confirmar',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            fontSize: 18,
          ),
        ),
        content: Text(
          text,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: action == 'Descartar'
                  ? AppColors.rejectedText
                  : AppColors.primaryContainer,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
