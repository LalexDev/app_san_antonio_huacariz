import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/cliente_portal_service.dart';
import '../../shared/widgets/cliente_bottom_nav.dart';

class MisSuministrosPage extends StatefulWidget {
  const MisSuministrosPage({super.key});

  @override
  State<MisSuministrosPage> createState() => _MisSuministrosPageState();
}

class _MisSuministrosPageState extends State<MisSuministrosPage> {
  final ClientePortalService clientePortalService = ClientePortalService();

  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;
  Color get background => context.jassBackground;
  Color get muted => context.jassTextMuted;
  static const Color danger = JassColors.danger;

  List<Map<String, dynamic>> suministros = [];

  bool cargando = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarSuministros();
  }

  Future<void> cargarSuministros() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await clientePortalService.listarMisSuministros();

      if (!mounted) return;

      setState(() {
        suministros = data;
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

  double _numero(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _codigo(Map<String, dynamic> suministro) {
    return _texto(
      suministro['codigoSuministro'] ??
          suministro['suministroCodigo'] ??
          suministro['codigo'] ??
          suministro['numeroSuministro'],
      'SIN-CODIGO',
    );
  }

  String _sector(Map<String, dynamic> suministro) {
    return _texto(
      suministro['nombreSector'] ??
          suministro['sector'] ??
          suministro['sectorNombre'],
      'Sector no registrado',
    );
  }

  String _direccion(Map<String, dynamic> suministro) {
    return _texto(
      suministro['direccionSuministro'] ??
          suministro['direccion'] ??
          suministro['direccionCliente'],
      'Dirección no registrada',
    );
  }

  String _referencia(Map<String, dynamic> suministro) {
    return _texto(
      suministro['referencia'] ?? suministro['referenciaSuministro'],
      'Sin referencia',
    );
  }

  String _alias(Map<String, dynamic> suministro) {
    return _texto(
      suministro['aliasSuministro'] ?? suministro['alias'],
      'Sin alias',
    );
  }

  double _lecturaInicial(Map<String, dynamic> suministro) {
    return _numero(
      suministro['lecturaInicial'] ??
          suministro['lecturaInicialM3'] ??
          suministro['lectura'],
    );
  }

  bool _activo(Map<String, dynamic> suministro) {
    final value = suministro['estado'];

    if (value is bool) return value;

    return value.toString().toLowerCase() == 'true' ||
        value.toString().toUpperCase() == 'ACTIVO';
  }

  void _irHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _irRecibos() {
    Navigator.pushReplacementNamed(context, '/recibos');
  }

  void _irPerfil() {
    Navigator.pushReplacementNamed(context, '/perfil');
  }

  void _irCambiarPassword() {
    Navigator.pushNamed(context, '/cambiar-password');
  }

  void _irPagar() {
    Navigator.pushReplacementNamed(context, '/recibos');
  }

  void _verDetalle(Map<String, dynamic> suministro) {
    Navigator.pushNamed(
      context,
      '/detalle-suministro-cliente',
      arguments: suministro,
    );
  }

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _irHome();
    }
  }

  // Barra inferior cliente:
  // 0 = Inicio, 1 = Recibos, 2 = Pagar, 3 = Perfil.
  // Esta pantalla no está en la barra principal, por eso usamos -1.
  void _goBottomCliente(int index) {
    if (index == 0) {
      _irHome();
    }

    if (index == 1) {
      _irRecibos();
    }

    if (index == 2) {
      _irPagar();
    }

    if (index == 3) {
      _irPerfil();
    }
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
                            _irHome();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Recibos',
                          onTap: () {
                            Navigator.pop(context);
                            _irRecibos();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.payments_rounded,
                          label: 'Pagar',
                          onTap: () {
                            Navigator.pop(context);
                            _irPagar();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.person_rounded,
                          label: 'Perfil',
                          onTap: () {
                            Navigator.pop(context);
                            _irPerfil();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.lock_reset_rounded,
                          label: 'Clave',
                          onTap: () {
                            Navigator.pop(context);
                            _irCambiarPassword();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.refresh_rounded,
                          label: 'Actualizar',
                          onTap: () {
                            Navigator.pop(context);
                            cargarSuministros();
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
        currentIndex: -1,
        onTap: _goBottomCliente,
        onPlus: _abrirMenuCliente,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarSuministros,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 18),
                _buildHero(),
                SizedBox(height: 18),
                if (cargando) _buildLoading(),
                if (error.isNotEmpty && !cargando) _buildError(),
                if (!cargando && error.isEmpty) _buildSuministrosList(),
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
                'Mis suministros',
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
            onPressed: cargarSuministros,
            icon: Icon(
              Icons.refresh_rounded,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
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
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              Icons.water_drop_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suministros asociados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '${suministros.length} suministro(s) registrado(s)',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            'Cargando suministros...',
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
        border: Border.all(
          color: const Color(0xFFFFD1D1),
        ),
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
            onPressed: cargarSuministros,
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

  Widget _buildSuministrosList() {
    if (suministros.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: context.jassSurface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: context.jassBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              color: secondary,
              size: 54,
            ),
            SizedBox(height: 12),
            Text(
              'No tienes suministros registrados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: suministros.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => SizedBox(height: 14),
      itemBuilder: (context, index) {
        final suministro = suministros[index];

        return _SuministroCard(
          codigo: _codigo(suministro),
          sector: _sector(suministro),
          direccion: _direccion(suministro),
          referencia: _referencia(suministro),
          alias: _alias(suministro),
          lecturaInicial: _lecturaInicial(suministro),
          activo: _activo(suministro),
          onTap: () => _verDetalle(suministro),
        );
      },
    );
  }
}

class _SuministroCard extends StatelessWidget {
  final String codigo;
  final String sector;
  final String direccion;
  final String referencia;
  final String alias;
  final double lecturaInicial;
  final bool activo;
  final VoidCallback onTap;

  const _SuministroCard({
    required this.codigo,
    required this.sector,
    required this.direccion,
    required this.referencia,
    required this.alias,
    required this.lecturaInicial,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    const Color secondary = JassColors.secondary;
    final Color muted = context.jassTextMuted;
    const Color success = Color(0xFF1F8F4D);
    const Color danger = Color(0xFFD93025);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.jassSurface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: context.jassBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: JassColors.primary.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.jassSelectedSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: secondary,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    codigo,
                    style: TextStyle(
                      color: primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: activo
                        ? const Color(0xFFEAF8EF)
                        : const Color(0xFFFFECEC),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    activo ? 'ACTIVO' : 'INACTIVO',
                    style: TextStyle(
                      color: activo ? success : danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            _InfoLine(
              icon: Icons.map_rounded,
              text: sector,
            ),
            _InfoLine(
              icon: Icons.place_rounded,
              text: direccion,
            ),
            _InfoLine(
              icon: Icons.bookmark_rounded,
              text: alias,
            ),
            _InfoLine(
              icon: Icons.info_outline_rounded,
              text: referencia,
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniBox(
                    label: 'Lectura inicial',
                    value: '${lecturaInicial.toStringAsFixed(3)} m³',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MiniBox(
                    label: 'Detalle',
                    value: 'Ver más',
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Spacer(),
                Text(
                  'Toca para ver detalle',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: muted,
                  size: 13,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({
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
          Icon(
            icon,
            size: 17,
            color: muted,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

class _MiniBox extends StatelessWidget {
  final String label;
  final String value;

  const _MiniBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    final Color muted = context.jassTextMuted;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
