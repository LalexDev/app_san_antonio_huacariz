import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color secondary = JassColors.secondary;

  final TextEditingController usuarioController =
      TextEditingController();
  final TextEditingController passwordController =
      TextEditingController();

  final AuthService authService = AuthService();
  final SecureStorageService storageService =
      SecureStorageService();

  bool mostrarPassword = false;
  bool cargando = false;
  bool ingresandoOffline = false;
  bool verificandoSesionOffline = true;
  bool puedeIngresarOffline = false;
  String rolSeleccionado = 'ADMINISTRADOR';

  String usuarioOffline = '';
  DateTime? ultimoLoginOnline;

  bool get procesando => cargando || ingresandoOffline;

  @override
  void initState() {
    super.initState();
    _prepararAcceso();
  }

  @override
  void dispose() {
    usuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _prepararAcceso() async {
    await authService.limpiarSesionNoPermitida();
    await _cargarSesionOffline();
  }

  Future<void> _cargarSesionOffline() async {
    final disponible =
        await authService.puedeIngresarOfflineComoLecturador();
    final usuario = await storageService.getUserName() ?? '';
    final fecha = await storageService.getLastOnlineLogin();

    if (!mounted) return;

    setState(() {
      puedeIngresarOffline = disponible;
      usuarioOffline = usuario;
      ultimoLoginOnline = fecha;
      verificandoSesionOffline = false;
    });

    if (disponible && usuarioController.text.trim().isEmpty) {
      usuarioController.text = usuario;
    }
  }

  String? _rutaPorRol(String? role) {
    if (storageService.esRolAdmin(role)) {
      return '/admin-dashboard';
    }

    if (storageService.esRolLecturador(role)) {
      return '/lector-home';
    }

    return null;
  }

  bool get esAdministradorSeleccionado =>
      rolSeleccionado == 'ADMINISTRADOR';

  bool get esLecturadorSeleccionado =>
      rolSeleccionado == 'LECTURADOR';

  void _seleccionarRol(String rol) {
    if (procesando) return;

    setState(() {
      rolSeleccionado = rol;
    });
  }

  Future<void> iniciarSesion() async {
    final usuario = usuarioController.text.trim();
    final password = passwordController.text;

    if (usuario.isEmpty || password.trim().isEmpty) {
      _mostrarMensaje(
        'Ingresa el código de usuario y la contraseña.',
        esError: true,
      );
      return;
    }

    if (procesando) return;

    setState(() {
      cargando = true;
    });

    try {
      await authService.login(
        codigoUsuario: usuario,
        password: password,
      );

      final role = await storageService.getUserRole();
      final ruta = _rutaPorRol(role);

      if (ruta == null) {
        await authService.logout();
        throw Exception(
          'Esta aplicación solo permite el acceso de '
          'ADMINISTRADOR y LECTURADOR.',
        );
      }

      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      Navigator.pushNamedAndRemoveUntil(
        context,
        ruta,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      final detalle = e
          .toString()
          .replaceFirst('Exception: ', '');

      _mostrarMensaje(
        puedeIngresarOffline
            ? 'No se pudo iniciar en línea: $detalle '
                'El lecturador guardado puede usar el modo sin conexión.'
            : detalle,
        esError: true,
      );
    }
  }

  Future<void> iniciarSesionOffline() async {
    if (procesando) return;

    setState(() {
      ingresandoOffline = true;
    });

    try {
      await authService.loginOfflineLector(
        codigoUsuario: usuarioController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        ingresandoOffline = false;
      });

      _mostrarMensaje(
        'Modo sin conexión activado. Las lecturas se '
        'guardarán en este dispositivo.',
        esError: false,
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/lector-home',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        ingresandoOffline = false;
      });

      _mostrarMensaje(
        e.toString().replaceFirst('Exception: ', ''),
        esError: true,
      );
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'No disponible';

    String dos(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  void _mostrarMensaje(
    String mensaje, {
    required bool esError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            esError ? JassColors.danger : JassColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login-fondo-huacariz.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: JassColors.primary);
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF061A24)
                        .withValues(alpha: 0.60),
                    const Color(0xFF0F3D57)
                        .withValues(alpha: 0.52),
                    const Color(0xFF1DA1C2)
                        .withValues(alpha: 0.30),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBrand(),
                  const SizedBox(height: 26),
                  _buildHeroText(),
                  const SizedBox(height: 24),
                  _buildLoginCard(),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'Acceso institucional · Agua Potable San Antonio',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBrand() {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(
            Icons.water_drop_outlined,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agua Potable San Antonio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Sistema de gestión y lectura del servicio de agua',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Acceso exclusivo para personal autorizado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Administración y lecturas\nen un solo sistema.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 35,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Gestiona clientes, suministros, tarifas, recibos y pagos; '
          'registra lecturas incluso cuando no exista conexión.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(
              child: _InfoMiniCard(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Administrador',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _InfoMiniCard(
                icon: Icons.speed_outlined,
                title: 'Lecturador',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _InfoMiniCard(
                icon: Icons.cloud_off_outlined,
                title: 'Modo offline',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: context.jassSelectedSurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              color: secondary,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ACCESO DEL PERSONAL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Administrador y lecturador',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          _label('Código de usuario'),
          const SizedBox(height: 8),
          TextField(
            controller: usuarioController,
            enabled: !procesando,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDecoration(
              hint: 'Ingresa tu código',
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 14),
          _label('Contraseña'),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            enabled: !procesando,
            obscureText: !mostrarPassword,
            onSubmitted: (_) {
              if (!procesando) iniciarSesion();
            },
            decoration: _inputDecoration(
              hint: 'Ingresa tu contraseña',
              icon: Icons.lock_outline,
              suffix: IconButton(
                onPressed: procesando
                    ? null
                    : () {
                        setState(() {
                          mostrarPassword = !mostrarPassword;
                        });
                      },
                icon: Icon(
                  mostrarPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _RoleAccessCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Administrador',
                  subtitle: 'Gestión completa del sistema',
                  selected: esAdministradorSeleccionado,
                  onTap: () => _seleccionarRol('ADMINISTRADOR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RoleAccessCard(
                  icon: Icons.speed_outlined,
                  title: 'Lecturador',
                  subtitle: 'Lecturas online y offline',
                  selected: esLecturadorSeleccionado,
                  onTap: () => _seleccionarRol('LECTURADOR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            esAdministradorSeleccionado
                ? 'Modo Administrador seleccionado.'
                : 'Modo Lecturador seleccionado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: procesando ? null : iniciarSesion,
              icon: cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(
                cargando ? 'Validando datos...' : 'Ingresar al sistema',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: JassColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (verificandoSesionOffline) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              minHeight: 3,
              color: secondary,
              backgroundColor: context.jassBorder,
            ),
          ],
          if (!verificandoSesionOffline &&
              puedeIngresarOffline) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.jassSelectedSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: secondary.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sesión offline del lecturador',
                          style: TextStyle(
                            color: context.jassTextPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Usuario: $usuarioOffline\n'
                    'Último acceso en línea: '
                    '${_formatearFecha(ultimoLoginOnline)}',
                    style: TextStyle(
                      color: context.jassTextMuted,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: procesando
                          ? null
                          : iniciarSesionOffline,
                      icon: ingresandoOffline
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: secondary,
                              ),
                            )
                          : const Icon(
                              Icons.offline_bolt_rounded,
                            ),
                      label: Text(
                        ingresandoOffline
                            ? 'Ingresando...'
                            : 'Trabajar sin conexión',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondary,
                        side: const BorderSide(
                          color: secondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El acceso offline está disponible únicamente '
                    'para el lecturador autenticado previamente.',
                    style: TextStyle(
                      color: context.jassTextMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            'Los usuarios clientes no tienen acceso a esta aplicación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String texto) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: TextStyle(
          color: context.jassTextPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: context.jassTextMuted,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: context.jassSurfaceAlt,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: context.jassBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: secondary,
          width: 1.5,
        ),
      ),
    );
  }
}

class _InfoMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _InfoMiniCard({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 105,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? context.jassSelectedSurface
              : context.jassSurfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? JassColors.secondary : context.jassBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 2),
            Icon(
              icon,
              color: JassColors.secondary,
              size: 25,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.jassTextPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.jassTextMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
