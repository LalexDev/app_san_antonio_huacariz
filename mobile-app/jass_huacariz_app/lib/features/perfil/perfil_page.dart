import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/cliente_portal_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../shared/widgets/cliente_bottom_nav.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;
  Color get background => context.jassBackground;
  Color get muted => context.jassTextMuted;
  static const Color danger = JassColors.danger;

  final ClientePortalService clientePortalService = ClientePortalService();
  final SecureStorageService storageService = SecureStorageService();

  Map<String, dynamic>? perfil;
  List<Map<String, dynamic>> suministros = [];

  bool cargando = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final perfilData = await clientePortalService.obtenerMiPerfil();
      final suministrosData =
          await clientePortalService.listarMisSuministros();

      if (!mounted) return;

      setState(() {
        perfil = perfilData;
        suministros = suministrosData;
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

  String _texto(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  String get nombreCompleto {
    final nombres = _texto(perfil?['nombres'], '');
    final apellidos = _texto(perfil?['apellidos'], '');

    final completo = '$nombres $apellidos'.trim();

    return completo.isEmpty ? 'Cliente del servicio' : completo;
  }

  String get codigoUsuario {
    return _texto(perfil?['codigoUsuario']);
  }

  String get dni {
    return _texto(perfil?['dni']);
  }

  String get telefono {
    return _texto(perfil?['telefono'] ?? perfil?['celular']);
  }

  String get correo {
    return _texto(perfil?['correo']);
  }

  bool get estado {
    final value = perfil?['estado'];

    if (value is bool) return value;

    return value.toString().toLowerCase() == 'true';
  }

  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Cerrar sesión',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '¿Deseas cerrar tu sesión actual?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: danger,
                foregroundColor: Colors.white,
              ),
              child: Text('Cerrar sesión'),
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

  void irCambiarPassword() {
    Navigator.pushNamed(context, '/cambiar-password');
  }

  void irHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void irRecibos() {
    Navigator.pushReplacementNamed(context, '/recibos');
  }

  void irPagar() {
    Navigator.pushReplacementNamed(context, '/recibos');
  }

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      irHome();
    }
  }

  // Barra inferior cliente:
  // 0 = Inicio, 1 = Recibos, 2 = Pagar, 3 = Perfil.
  void _goBottomCliente(int index) {
    if (index == 0) {
      irHome();
    }

    if (index == 1) {
      irRecibos();
    }

    if (index == 2) {
      irPagar();
    }

    if (index == 3) return;
  }

  void _abrirMenuCliente() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      isScrollControlled: true,
      builder: (_) {
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
                      color: context.jassSurface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: context.jassBorder,
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
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                      children: [
                        ClienteMenuTile(
                          icon: Icons.home_rounded,
                          label: 'Inicio',
                          onTap: () {
                            Navigator.pop(context);
                            irHome();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Recibos',
                          onTap: () {
                            Navigator.pop(context);
                            irRecibos();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.payments_rounded,
                          label: 'Pagar',
                          onTap: () {
                            Navigator.pop(context);
                            irPagar();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.lock_reset_rounded,
                          label: 'Clave',
                          onTap: () {
                            Navigator.pop(context);
                            irCambiarPassword();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.refresh_rounded,
                          label: 'Actualizar',
                          onTap: () {
                            Navigator.pop(context);
                            cargarDatos();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.logout_rounded,
                          label: 'Salir',
                          onTap: () {
                            Navigator.pop(context);
                            cerrarSesion();
                          },
                        ),
                        ClienteThemeTile(
                          onAfterChange: () {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: JassColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: ClienteBottomNav(
        currentIndex: 3,
        onTap: _goBottomCliente,
        onPlus: _abrirMenuCliente,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarDatos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 18),
                if (cargando) _buildLoading(),
                if (error.isNotEmpty && !cargando) _buildError(),
                if (!cargando && error.isEmpty) ...[
                  _buildProfileCard(),
                  SizedBox(height: 18),
                  _buildActions(),
                  SizedBox(height: 18),
                  _buildSuministros(),
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
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: context.jassSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: JassColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _volver,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: primary,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Portal cliente',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Mi perfil',
                style: TextStyle(
                  color: primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: context.jassSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: JassColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            onPressed: cargarDatos,
            icon: Icon(
              Icons.refresh_rounded,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Cargando perfil...',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD1D1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: danger,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: danger,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14),
          ElevatedButton(
            onPressed: cargarDatos,
            style: ElevatedButton.styleFrom(
              backgroundColor: secondary,
              foregroundColor: Colors.white,
            ),
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
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
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: JassColors.primary.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          SizedBox(height: 14),
          Text(
            nombreCompleto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Código: $codigoUsuario',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: estado
                  ? const Color(0xFFEAF8EF)
                  : const Color(0xFFFFECEC),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              estado ? 'ACTIVO' : 'INACTIVO',
              style: TextStyle(
                color: estado
                    ? const Color(0xFF1F8F4D)
                    : const Color(0xFFD93025),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(height: 18),
          _InfoProfileRow(
            icon: Icons.badge_rounded,
            label: 'DNI',
            value: dni,
          ),
          _InfoProfileRow(
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: telefono,
          ),
          _InfoProfileRow(
            icon: Icons.email_rounded,
            label: 'Correo',
            value: correo,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: irCambiarPassword,
            icon: Icon(Icons.lock_reset_rounded),
            label: Text(
              'Cambiar contraseña',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: cerrarSesion,
            icon: Icon(Icons.logout_rounded),
            label: Text(
              'Cerrar sesión',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: danger,
              backgroundColor: context.jassSurface,
              side: BorderSide(color: Color(0xFFFFD1D1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuministros() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis suministros',
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          if (suministros.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No tienes suministros registrados.',
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: suministros.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, _) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final suministro = suministros[index];

                return _SuministroCard(
                  codigo: _texto(suministro['codigoSuministro']),
                  sector: _texto(suministro['nombreSector']),
                  direccion: _texto(suministro['direccionSuministro']),
                  referencia: _texto(suministro['referencia']),
                  alias: _texto(suministro['aliasSuministro']),
                  lecturaInicial: _texto(suministro['lecturaInicial']),
                  activo: suministro['estado'] == true ||
                      suministro['estado'].toString().toLowerCase() == 'true',
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InfoProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Color(0xFFE7F8FF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuministroCard extends StatelessWidget {
  final String codigo;
  final String sector;
  final String direccion;
  final String referencia;
  final String alias;
  final String lecturaInicial;
  final bool activo;

  const _SuministroCard({
    required this.codigo,
    required this.sector,
    required this.direccion,
    required this.referencia,
    required this.alias,
    required this.lecturaInicial,
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    final Color muted = context.jassTextMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.jassSelectedSurface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: Color(0xFF1DA1C2),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  codigo,
                  style: TextStyle(
                    color: primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: activo
                      ? const Color(0xFFEAF8EF)
                      : const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: activo
                        ? const Color(0xFF1F8F4D)
                        : const Color(0xFFD93025),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _SuministroInfo(icon: Icons.map_rounded, text: sector),
          _SuministroInfo(icon: Icons.place_rounded, text: direccion),
          _SuministroInfo(icon: Icons.bookmark_rounded, text: alias),
          _SuministroInfo(icon: Icons.info_outline_rounded, text: referencia),
          _SuministroInfo(
            icon: Icons.speed_rounded,
            text: 'Lectura inicial: $lecturaInicial',
          ),
        ],
      ),
    );
  }
}

class _SuministroInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SuministroInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final Color muted = context.jassTextMuted;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: muted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
