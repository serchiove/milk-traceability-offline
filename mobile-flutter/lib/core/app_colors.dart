import 'package:flutter/material.dart';

/// Paleta central. Cambiar primaryAction modifica los botones principales.
class AppColors {
  // Colores de marca y acciones principales.
  static const primary = Color(0xFF12364A);
  static const primaryContainer = Color(0xFF155E75);
  static const primaryAction = primaryContainer;
  static const primaryLight = Color(0xFF1E5BB8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF93B8FD);

  // Interactive Accents
  static const secondary = Color(0xFF087F83);
  static const secondaryContainer = Color(0xFF2563EB);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryFixed = Color(0xFFDDF2F0);
  static const onSecondaryFixed = Color(0xFF115E59);
  static const onSecondaryFixedVariant = Color(0xFF1E3A8A);

  // Surfaces & Backgrounds
  static const background = Color(0xFFF4F6F9);
  static const surface = Color(0xFFF4F6F9);
  static const surfaceDim = Color(0xFFE2E8F0);
  static const surfaceBright = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF8FAFC);
  static const surfaceContainer = Color(0xFFF1F5F9);
  static const surfaceContainerHigh = Color(0xFFE2E8F0);
  static const surfaceContainerHighest = Color(0xFFCBD5E1);

  // Typography Neutrals (High Contrast Slate)
  static const onSurface = Color(0xFF0F172A);
  static const onSurfaceVariant = Color(0xFF475569);
  static const outline = Color(0xFF64748B);
  static const outlineVariant = Color(0xFFCBD5E1);
  static const border = Color(0xFFE2E8F0);
  static const borderFocused = Color(0xFF2563EB);

  // Semantic Status Triplets (Text/Icon, Container, Border)
  // Aprobado (Conforming / Accepted)
  static const approvedText = Color(0xFF15803D);
  static const approvedContainer = Color(0xFFDCFCE7);
  static const approvedBorder = Color(0xFF86EFAC);

  // Rechazado (Rejected / Non-compliant)
  static const rejectedText = Color(0xFFB91C1C);
  static const rejectedContainer = Color(0xFFFEE2E2);
  static const rejectedBorder = Color(0xFFFCA5A5);

  // Pendiente / Alerta (Pending sync / Warning)
  static const pendingText = Color(0xFFB45309);
  static const pendingContainer = Color(0xFFFEF3C7);
  static const pendingBorder = Color(0xFFFCD34D);

  // Guardado Local / Offline (Device Cache)
  static const localText = Color(0xFF334155);
  static const localContainer = Color(0xFFF1F5F9);
  static const localBorder = Color(0xFFCBD5E1);

  // Recibido por servidor (Server sync confirmation)
  static const serverText = Color(0xFF1D4ED8);
  static const serverContainer = Color(0xFFDDF2F0);
  static const serverBorder = Color(0xFF93C5FD);
}
