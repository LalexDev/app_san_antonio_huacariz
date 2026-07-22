import 'package:flutter/material.dart';

import '../../core/app_theme_controller.dart';
import '../theme/jass_colors.dart';

class ClienteBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onPlus;

  const ClienteBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 66,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: oscuro ? JassColors.darkCard : JassColors.card,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: oscuro ? JassColors.darkBorder : JassColors.border,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _BottomItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.home_rounded,
                      tooltip: 'Inicio',
                      onTap: onTap,
                    ),
                    _BottomItem(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.receipt_long_rounded,
                      tooltip: 'Recibos',
                      onTap: onTap,
                    ),
                    _BottomItem(
                      index: 2,
                      currentIndex: currentIndex,
                      icon: Icons.payments_rounded,
                      tooltip: 'Pagar',
                      onTap: onTap,
                    ),
                    _BottomItem(
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.person_rounded,
                      tooltip: 'Perfil',
                      onTap: onTap,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onPlus,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: oscuro ? JassColors.darkCard : JassColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: oscuro ? JassColors.darkBorder : JassColors.border,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: oscuro ? Colors.white : JassColors.primary,
                  size: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String tooltip;
  final ValueChanged<int> onTap;

  const _BottomItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final seleccionado = index == currentIndex;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: seleccionado
                  ? oscuro
                      ? const Color(0xFF162432)
                      : const Color(0xFFE8F7FB)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Icon(
                icon,
                color: seleccionado
                    ? JassColors.secondary
                    : oscuro
                        ? JassColors.darkMuted
                        : JassColors.primary,
                size: seleccionado ? 28 : 25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClienteMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const ClienteMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: oscuro ? const Color(0xFF162432) : const Color(0xFFF4F8FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: oscuro ? JassColors.darkBorder : JassColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: danger ? JassColors.danger : JassColors.secondary,
              size: 30,
            ),
            const SizedBox(height: 9),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: danger
                    ? JassColors.danger
                    : oscuro
                        ? Colors.white
                        : JassColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClienteThemeTile extends StatelessWidget {
  final VoidCallback? onAfterChange;

  const ClienteThemeTile({super.key, this.onAfterChange});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        final esOscuro = mode == ThemeMode.dark;
        final oscuro = Theme.of(context).brightness == Brightness.dark;

        return InkWell(
          onTap: () {
            appThemeMode.value = esOscuro ? ThemeMode.light : ThemeMode.dark;
            onAfterChange?.call();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: oscuro
                  ? const Color(0xFF162432)
                  : const Color(0xFFF4F8FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: oscuro ? JassColors.darkBorder : JassColors.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  esOscuro
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: JassColors.secondary,
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  esOscuro ? 'Claro' : 'Oscuro',
                  style: TextStyle(
                    color: oscuro ? Colors.white : JassColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
