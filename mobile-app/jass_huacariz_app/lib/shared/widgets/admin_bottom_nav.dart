import 'package:flutter/material.dart';

import '../../core/app_theme_controller.dart';
import '../theme/jass_colors.dart';

/// Barra inferior principal del administrador.
///
/// Índices:
/// 0 = Dashboard
/// 1 = Clientes
/// 2 = Tarifas
/// 3 = Recibos
class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onPlus;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final bool oscuro =
        Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 66,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: oscuro
                      ? JassColors.darkCard
                      : JassColors.card,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: oscuro
                        ? JassColors.darkBorder
                        : JassColors.border,
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
                    _AdminBottomItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.dashboard_rounded,
                      tooltip: 'Inicio',
                      onTap: onTap,
                    ),
                    _AdminBottomItem(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.groups_rounded,
                      tooltip: 'Clientes',
                      onTap: onTap,
                    ),
                    _AdminBottomItem(
                      index: 2,
                      currentIndex: currentIndex,
                      icon: Icons.price_change_rounded,
                      tooltip: 'Tarifas',
                      onTap: onTap,
                    ),
                    _AdminBottomItem(
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.receipt_long_rounded,
                      tooltip: 'Recibos',
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
                  color: oscuro
                      ? JassColors.darkCard
                      : JassColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: oscuro
                        ? JassColors.darkBorder
                        : JassColors.border,
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
                  color: oscuro
                      ? Colors.white
                      : JassColors.primary,
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

class _AdminBottomItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String tooltip;
  final ValueChanged<int> onTap;

  const _AdminBottomItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool seleccionado = index == currentIndex;
    final bool oscuro =
        Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
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

/// Abre el menú reutilizable del botón "+" del administrador.
///
/// El menú mantiene fondo blanco en modo claro y fondo oscuro
/// cuando se activa el modo oscuro.
Future<void> showAdminQuickMenu({
  required BuildContext context,
  VoidCallback? onRefresh,
  VoidCallback? onLogout,
}) async {
  final bool oscuro =
      Theme.of(context).brightness == Brightness.dark;

  void abrirRuta(String ruta) {
    Navigator.pop(context);
    Navigator.pushNamed(context, ruta);
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.30),
    isScrollControlled: true,
    builder: (sheetContext) {
      void abrirDesdeMenu(String ruta) {
        Navigator.pop(sheetContext);
        Navigator.pushNamed(context, ruta);
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: oscuro
                        ? JassColors.darkCard
                        : JassColors.card,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: oscuro
                          ? JassColors.darkBorder
                          : JassColors.border,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                    children: [
  AdminMenuTile(
    icon: Icons.badge_rounded,
    label: 'Lecturadores',
    onTap: () {
      abrirDesdeMenu('/admin-lecturadores');
    },
  ),
  AdminMenuTile(
    icon: Icons.map_rounded,
    label: 'Sectores',
    onTap: () {
      abrirDesdeMenu('/admin-sectores');
    },
  ),
  AdminMenuTile(
    icon: Icons.payments_rounded,
    label: 'Pagos',
    onTap: () {
      abrirDesdeMenu('/admin-pagos');
    },
  ),
  AdminMenuTile(
    icon: Icons.qr_code_2_rounded,
    label: 'Generar QR',
    onTap: () {
      abrirDesdeMenu('/admin-qr-suministro');
    },
  ),
  AdminMenuTile(
    icon: Icons.qr_code_scanner_rounded,
    label: 'Escanear',
    onTap: () {
      abrirDesdeMenu('/admin-qr-scanner');
    },
  ),
  AdminMenuTile(
    icon: Icons.history_rounded,
    label: 'Lecturas',
    onTap: () {
      abrirDesdeMenu('/admin-historial-lecturas');
    },
  ),
  AdminMenuTile(
    icon: Icons.bar_chart_rounded,
    label: 'Reportes',
    onTap: () {
      abrirDesdeMenu('/admin-reportes');
    },
  ),
  if (onRefresh != null)
    AdminMenuTile(
      icon: Icons.refresh_rounded,
      label: 'Actualizar',
      onTap: () {
        Navigator.pop(sheetContext);
        onRefresh();
      },
    ),
  if (onLogout != null)
    AdminMenuTile(
      icon: Icons.logout_rounded,
      label: 'Salir',
      danger: true,
      onTap: () {
        Navigator.pop(sheetContext);
        onLogout();
      },
    ),
  const AdminThemeTile(),
],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => Navigator.pop(sheetContext),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: oscuro
                        ? JassColors.darkCard
                        : JassColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: oscuro
                          ? JassColors.darkBorder
                          : JassColors.primary,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Opción reutilizable del menú "+" del administrador.
class AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const AdminMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool oscuro =
        Theme.of(context).brightness == Brightness.dark;

    final Color iconColor =
        danger ? JassColors.danger : JassColors.secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: oscuro
              ? const Color(0xFF162432)
              : const Color(0xFFF4F8FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: oscuro
                ? JassColors.darkBorder
                : JassColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
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

/// Botón para cambiar entre modo claro y oscuro.
class AdminThemeTile extends StatelessWidget {
  const AdminThemeTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) {
        final bool esOscuro = mode == ThemeMode.dark;
        final bool oscuro =
            Theme.of(context).brightness == Brightness.dark;

        return InkWell(
          onTap: () {
            appThemeMode.value = esOscuro
                ? ThemeMode.light
                : ThemeMode.dark;
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: oscuro
                  ? const Color(0xFF162432)
                  : const Color(0xFFF4F8FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: oscuro
                    ? JassColors.darkBorder
                    : JassColors.border,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: oscuro
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
      },
    );
  }
}