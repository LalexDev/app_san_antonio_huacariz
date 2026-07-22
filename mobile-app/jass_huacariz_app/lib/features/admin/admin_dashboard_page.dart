import 'package:flutter/material.dart';

import '../../core/services/cliente_service.dart';
import '../../core/services/recibo_service.dart';
import '../../core/services/pago_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/app_theme_controller.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const Color primary = Color(0xFF0F3D57);
  static const Color secondary = Color(0xFF1DA1C2);
  static const Color lightBackground = Color(0xFFEFF7FB);
  static const Color darkBackground = Color(0xFF07111C);
  static const Color muted = Color(0xFF7B8794);

  final ClienteService clienteService = ClienteService();
  final ReciboService reciboService = ReciboService();
  final PagoService pagoService = PagoService();
  final SecureStorageService storageService = SecureStorageService();

  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> recibos = [];
  List<Map<String, dynamic>> pagos = [];

  bool cargando = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarDashboard();
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _bg(BuildContext context) {
    return _isDark(context) ? darkBackground : lightBackground;
  }

  Color _card(BuildContext context) {
    return _isDark(context) ? const Color(0xFF101820) : Colors.white;
  }

  Color _text(BuildContext context) {
    return _isDark(context) ? Colors.white : primary;
  }

  Color _mutedText(BuildContext context) {
    return _isDark(context) ? const Color(0xFF9EB4C0) : muted;
  }

  Color _border(BuildContext context) {
    return _isDark(context) ? const Color(0xFF223344) : const Color(0xFFE2EDF3);
  }

  Future<void> cargarDashboard() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await Future.wait([
        clienteService.listarClientes(),
        reciboService.listarRecibosAdmin(),
        pagoService.listarPagos(),
      ]);

      if (!mounted) return;

      setState(() {
        clientes = data[0];
        recibos = data[1];
        pagos = data[2];
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        cargando = false;
      });
    }
  }

  String _estado(Map<String, dynamic> recibo) {
    return (recibo['estadoRecibo'] ?? recibo['estado'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
  }

  double _numero(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int get totalClientes => clientes.length;

  int get recibosPendientes {
    return recibos.where((recibo) => _estado(recibo) == 'PENDIENTE').length;
  }

  int get recibosPagados {
    return recibos.where((recibo) => _estado(recibo) == 'PAGADO').length;
  }

  int get recibosVencidos {
    return recibos.where((recibo) => _estado(recibo) == 'VENCIDO').length;
  }

  int get lecturasMes => recibos.length;

  double get recaudacion {
    return pagos.fold(0.0, (sum, pago) {
      return sum + _numero(pago['monto'] ?? pago['total']);
    });
  }

  void _ir(String route) {
    Navigator.pushNamed(context, route);
  }


  void _go(int index) {
    if (index == 0) return;

    if (index == 1) {
      _ir('/admin-clientes');
    }

    if (index == 2) {
      _ir('/admin-tarifas');
    }

    if (index == 3) {
      _ir('/admin-recibos');
    }
  }

  void _abrirMenuRapido() {
    showAdminQuickMenu(
      context: context,
      onRefresh: cargarDashboard,
      onLogout: cerrarSesion,
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('¿Deseas cerrar la sesión de administrador?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD93025),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await storageService.clearSession();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      extendBody: true,
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 0,
        onTap: _go,
        onPlus: _abrirMenuRapido,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildHero(),
                const SizedBox(height: 18),
                if (cargando) _buildLoading(),
                if (error.isNotEmpty && !cargando)
                  _ErrorBox(
                    error: error,
                    onRetry: cargarDashboard,
                  ),
                if (!cargando && error.isEmpty) ...[
                  _buildStatsGrid(),
                  const SizedBox(height: 20),
                  Text(
                    'Accesos rápidos',
                    style: TextStyle(
                      color: _text(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  _buildGestionCards(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel del administrador',
                style: TextStyle(
                  color: _mutedText(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dashboard',
                style: TextStyle(
                  color: _text(context),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _CircleButton(
          icon: appThemeMode.value == ThemeMode.dark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          onTap: () {
            appThemeMode.value = appThemeMode.value == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.dark;

            setState(() {});
          },
        ),
        const SizedBox(width: 10),
        _CircleButton(
          icon: Icons.refresh_rounded,
          onTap: cargarDashboard,
        ),
        const SizedBox(width: 10),
        _CircleButton(
          icon: Icons.logout_rounded,
          onTap: cerrarSesion,
          danger: true,
        ),
      ],
    );
  }

  Widget _buildHero() {
    return InkWell(
      onTap: () => _ir('/admin-reportes'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0F3D57),
              Color(0xFF1DA1C2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AGUA POTABLE HUACARIZ SAN ANTONIO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Resumen operativo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Toca para ver reportes generales.',
                    style: TextStyle(
                      color: Color(0xFFE7F8FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border(context)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(
            'Cargando dashboard...',
            style: TextStyle(
              color: _mutedText(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.12,
      children: [
        _StatCard(
          icon: Icons.groups_rounded,
          label: 'Clientes',
          value: '$totalClientes',
          subtitle: 'Ver lista',
          color: secondary,
          onTap: () => _ir('/admin-clientes'),
        ),
        _StatCard(
          icon: Icons.pending_actions_rounded,
          label: 'Pendientes',
          value: '$recibosPendientes',
          subtitle: 'Ver recibos',
          color: const Color(0xFFC77700),
          onTap: () => _ir('/admin-recibos'),
        ),
        _StatCard(
          icon: Icons.check_circle_rounded,
          label: 'Pagados',
          value: '$recibosPagados',
          subtitle: 'Ver pagos',
          color: const Color(0xFF1F8F4D),
          onTap: () => _ir('/admin-recibos'),
        ),
        _StatCard(
          icon: Icons.warning_rounded,
          label: 'Vencidos',
          value: '$recibosVencidos',
          subtitle: 'Revisar deuda',
          color: const Color(0xFFD93025),
          onTap: () => _ir('/admin-recibos'),
        ),
        _StatCard(
          icon: Icons.payments_rounded,
          label: 'Recaudación',
          value: 'S/ ${recaudacion.toStringAsFixed(2)}',
          subtitle: 'Ver reportes',
          color: secondary,
          onTap: () => _ir('/admin-reportes'),
        ),
        _StatCard(
          icon: Icons.speed_rounded,
          label: 'Lecturas',
          value: '$lecturasMes',
          subtitle: 'Ver recibos',
          color: const Color(0xFF146C94),
          onTap: () => _ir('/admin-recibos'),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        _QuickAction(
          label: 'Clientes',
          icon: Icons.people_alt_rounded,
          onTap: () => _ir('/admin-clientes'),
        ),
        _QuickAction(
          label: 'Lecturadores',
          icon: Icons.badge_rounded,
          onTap: () => _ir('/admin-lecturadores'),
        ),
        _QuickAction(
          label: 'Sectores',
          icon: Icons.map_rounded,
          onTap: () => _ir('/admin-sectores'),
        ),
        _QuickAction(
          label: 'Pagos',
          icon: Icons.payments_rounded,
          onTap: () => _ir('/admin-pagos'),
        ),
        _QuickAction(
          label: 'QR',
          icon: Icons.qr_code_2_rounded,
          onTap: () => _ir('/admin-qr-suministro'),
        ),
        _QuickAction(
          label: 'Tarifas',
          icon: Icons.attach_money_rounded,
          onTap: () => _ir('/admin-tarifas'),
        ),
        _QuickAction(
          label: 'Recibos',
          icon: Icons.receipt_long_rounded,
          onTap: () => _ir('/admin-recibos'),
        ),
        _QuickAction(
          label: 'Reportes',
          icon: Icons.bar_chart_rounded,
          onTap: () => _ir('/admin-reportes'),
        ),
      ],
    );
  }

  Widget _buildGestionCards() {
    return Column(
      children: [
        _GestionTile(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Gestionar clientes y suministros',
          subtitle: 'Registrar clientes, ver detalle, editar y consultar QR.',
          onTap: () => _ir('/admin-clientes'),
        ),
        const SizedBox(height: 12),
        _GestionTile(
          icon: Icons.badge_rounded,
          title: 'Gestionar lecturadores',
          subtitle:
              'Crear usuarios lecturadores, editar datos y habilitar acceso.',
          onTap: () => _ir('/admin-lecturadores'),
        ),
        const SizedBox(height: 12),
        _GestionTile(
          icon: Icons.map_rounded,
          title: 'Gestionar sectores',
          subtitle:
              'Crear, editar, activar y desactivar sectores para suministros.',
          onTap: () => _ir('/admin-sectores'),
        ),
        const SizedBox(height: 12),
        _GestionTile(
          icon: Icons.payments_rounded,
          title: 'Pagos y recaudación',
          subtitle:
              'Consultar pagos registrados, métodos de pago y montos recaudados.',
          onTap: () => _ir('/admin-pagos'),
        ),
        const SizedBox(height: 12),
        _GestionTile(
          icon: Icons.qr_code_2_rounded,
          title: 'QR de suministro',
          subtitle:
              'Generar ficha QR por código de suministro para lectura mensual.',
          onTap: () => _ir('/admin-qr-suministro'),
        ),
        const SizedBox(height: 12),
        _GestionTile(
          icon: Icons.water_drop_rounded,
          title: 'Configurar tarifas',
          subtitle: 'Actualizar cargos, tramos y configuración de cobranza.',
          onTap: () => _ir('/admin-tarifas'),
        ),
        const SizedBox(height: 12),
        _GestionTile(
          icon: Icons.receipt_long_rounded,
          title: 'Control de recibos',
          subtitle: 'Revisar recibos pendientes, pagados y vencidos.',
          onTap: () => _ir('/admin-recibos'),
        ),
        const SizedBox(height: 12),
        _GestionTile(
          icon: Icons.analytics_rounded,
          title: 'Reportes administrativos',
          subtitle: 'Consultar resumen, recaudación, mora y consumo.',
          onTap: () => _ir('/admin-reportes'),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF101820) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0xFF223344) : const Color(0xFFE2EDF3),
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: danger
              ? const Color(0xFFD93025)
              : dark
                  ? Colors.white
                  : const Color(0xFF0F3D57),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF101820) : Colors.white;
    final text = dark ? Colors.white : const Color(0xFF0F3D57);
    final muted = dark ? const Color(0xFF9EB4C0) : const Color(0xFF7B8794);
    final border = dark ? const Color(0xFF223344) : const Color(0xFFE2EDF3);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: muted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF101820) : Colors.white;
    final text = dark ? Colors.white : const Color(0xFF0F3D57);
    final border = dark ? const Color(0xFF223344) : const Color(0xFFE2EDF3);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.circle,
              color: Colors.transparent,
              size: 0,
            ),
            Icon(icon, color: const Color(0xFF1DA1C2), size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GestionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GestionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF101820) : Colors.white;
    final text = dark ? Colors.white : const Color(0xFF0F3D57);
    final muted = dark ? const Color(0xFF9EB4C0) : const Color(0xFF7B8794);
    final border = dark ? const Color(0xFF223344) : const Color(0xFFE2EDF3);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF162432)
                    : const Color(0xFFE8F7FB),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: const Color(0xFF1DA1C2)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorBox({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD93025),
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD93025),
              fontWeight: FontWeight.w800,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
