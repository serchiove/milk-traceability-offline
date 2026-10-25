import 'package:flutter/material.dart';

class AppColors {
  // Brand & Chrome (Google Stitch Acopio Gloria - High-End Enterprise)
  static const primary = Color(0xFF001E4D);
  static const primaryContainer = Color(0xFF0A387E);
  static const primaryLight = Color(0xFF1E5BB8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF93B8FD);

  // Interactive Accents
  static const secondary = Color(0xFF1A56DB);
  static const secondaryContainer = Color(0xFF2563EB);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryFixed = Color(0xFFDBEAFE);
  static const onSecondaryFixed = Color(0xFF1E40AF);
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
  static const serverContainer = Color(0xFFDBEAFE);
  static const serverBorder = Color(0xFF93C5FD);
}

ThemeData acopioTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    error: AppColors.rejectedText,
    onError: Colors.white,
    errorContainer: AppColors.rejectedContainer,
    onErrorContainer: AppColors.rejectedText,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 2,
      shadowColor: Color.fromRGBO(0, 0, 0, 0.05),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderFocused, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.rejectedText, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.rejectedText, width: 2),
      ),
      labelStyle: const TextStyle(
        color: AppColors.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(color: AppColors.outline, fontSize: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: const Color.fromRGBO(10, 56, 126, 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        foregroundColor: AppColors.primaryContainer,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.secondaryFixed,
      elevation: 4,
      shadowColor: const Color.fromRGBO(0, 0, 0, 0.08),
      height: 68,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.onSecondaryFixed, size: 24);
        }
        return const IconThemeData(color: AppColors.outline, size: 22);
      }),
    ),
  );
}
