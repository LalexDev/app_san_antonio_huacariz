import 'package:flutter/material.dart';

import 'jass_colors.dart';

/// Colores dinámicos de JASS según el modo claro u oscuro.
extension JassThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get jassBackground =>
      isDarkMode ? JassColors.darkBackground : JassColors.background;

  Color get jassSurface =>
      isDarkMode ? JassColors.darkCard : JassColors.card;

  Color get jassSurfaceAlt =>
      isDarkMode ? const Color(0xFF162432) : const Color(0xFFF8FBFD);

  Color get jassBorder =>
      isDarkMode ? JassColors.darkBorder : JassColors.border;

  Color get jassTextPrimary =>
      isDarkMode ? Colors.white : JassColors.primary;

  Color get jassTextMuted =>
      isDarkMode ? JassColors.darkMuted : JassColors.muted;

  Color get jassSelectedSurface =>
      isDarkMode ? const Color(0xFF193143) : const Color(0xFFE8F7FB);

  Color get jassShadow => isDarkMode
      ? Colors.black.withValues(alpha: 0.28)
      : Colors.black.withValues(alpha: 0.08);
}
