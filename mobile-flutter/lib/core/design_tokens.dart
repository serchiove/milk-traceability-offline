import 'package:flutter/material.dart';

/// Espaciado común de páginas y tarjetas.
abstract final class AppSpacing {
  static const page = 16.0;
  static const card = 16.0;
  static const gap = 12.0;
  static const pagePadding = EdgeInsets.fromLTRB(page, 14, page, 96);
}

/// Dimensiones comunes de controles táctiles.
abstract final class AppSizes {
  static const buttonHeight = 52.0;
}
