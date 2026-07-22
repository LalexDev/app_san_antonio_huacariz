import 'package:flutter/material.dart';

import 'jass_colors.dart';

/// Colores dinámicos según el modo claro u oscuro.
///
/// Uso:
/// context.jassBackground
/// context.jassSurface
/// context.jassTextPrimary
extension JassThemeContext on BuildContext {
  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }

  /// Fondo general de las páginas.
  Color get jassBackground {
    return isDarkMode
        ? JassColors.darkBackground
        : JassColors.background;
  }

  /// Fondo principal de tarjetas, formularios y menús.
  Color get jassSurface {
    return isDarkMode
        ? JassColors.darkCard
        : JassColors.card;
  }

  /// Fondo secundario de cajas internas y campos.
  Color get jassSurfaceAlt {
    return isDarkMode
        ? const Color(0xFF162432)
        : const Color(0xFFF8FBFD);
  }

  /// Color de los bordes.
  Color get jassBorder {
    return isDarkMode
        ? JassColors.darkBorder
        : JassColors.border;
  }

  /// Texto principal.
  Color get jassTextPrimary {
    return isDarkMode
        ? Colors.white
        : JassColors.primary;
  }

  /// Texto secundario.
  Color get jassTextMuted {
    return isDarkMode
        ? JassColors.darkMuted
        : JassColors.muted;
  }

  /// Fondo seleccionado.
  Color get jassSelectedSurface {
    return isDarkMode
        ? const Color(0xFF193143)
        : const Color(0xFFE8F7FB);
  }

  /// Sombra adaptada.
  Color get jassShadow {
    return isDarkMode
        ? Colors.black.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: 0.08);
  }
} 