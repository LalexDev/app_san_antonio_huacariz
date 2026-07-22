import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/cliente_portal_service.dart';
import '../../core/services/recibo_service.dart';
import '../../shared/widgets/cliente_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;
  Color get background => context.jassBackground;
  Color get muted => context.jassTextMuted;

  final ClientePortalService clientePortalService = ClientePortalService();
  final ReciboService reciboService = ReciboService();

  Map<String, dynamic>? perfil;
  List<Map<String, dynamic>> suministros = [];
  List<Map<String, dynamic>> recibos = [];

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
      final recibosData = await reciboService.listarMisRecibos();

      if (!mounted) return;

      setState(() {
        perfil = perfilData;
        suministros = suministrosData;
        recibos = recibosData;
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

  int _id(Map<String, dynamic> recibo) {
    final value = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  String _estado(Map<String, dynamic> recibo) {
    return _texto(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    ).toUpperCase();
  }

  double _total(Map<String, dynamic> recibo) {
    return _numero(
      recibo['total'] ??
          recibo['montoTotal'] ??
          recibo['importeTotal'] ??
          recibo['totalPagar'] ??
          0,
    );
  }

  double _consumo(Map<String, dynamic> recibo) {
    return _numero(
      recibo['consumoM3'] ?? recibo['consumo'] ?? recibo['consumoMes'] ?? 0,
    );
  }

  String _codigoRecibo(Map<String, dynamic> recibo) {
    return _texto(
      recibo['codigoRecibo'] ??
          recibo['numeroRecibo'] ??
          recibo['codigo'] ??
          'REC-${_id(recibo)}',
    );
  }

  String _codigoSuministro(Map<String, dynamic> recibo) {
    return _texto(
      recibo['codigoSuministro'] ??
          recibo['suministroCodigo'] ??
          recibo['suministro'] ??
          'SIN-SUMINISTRO',
    );
  }

  String _periodo(Map<String, dynamic> recibo) {
    final mes = recibo['mes'];
    final anio = recibo['anio'];

    if (mes != null && anio != null) {
      const meses = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];

      final mesNumero = int.tryParse(mes.toString()) ?? 1;
      final index = (mesNumero - 1).clamp(0, 11);

      return '${meses[index]} $anio';
    }

    return _texto(
      recibo['periodo'] ?? recibo['mesFacturado'],
      'Periodo no registrado',
    );
  }

  int _periodoNumero(Map<String, dynamic> recibo) {
    final anio = int.tryParse('${recibo['anio'] ?? 0}') ?? 0;
    final mes = int.tryParse('${recibo['mes'] ?? 0}') ?? 0;

    return anio * 100 + mes;
  }

  List<Map<String, dynamic>> get recibosOrdenados {
    final lista = [...recibos];

    lista.sort((a, b) {
      return _periodoNumero(b).compareTo(_periodoNumero(a));
    });

    return lista;
  }

  String get nombreCliente {
    final nombres = _texto(perfil?['nombres'], '');
    final apellidos = _texto(perfil?['apellidos'], '');

    final nombreCompleto = '$nombres $apellidos'.trim();

    if (nombreCompleto.isEmpty) {
      return 'Cliente';
    }

    return _capitalizar(nombreCompleto);
  }

  String _capitalizar(String texto) {
    return texto
        .split(' ')
        .where((p) => p.trim().isNotEmpty)
        .map((p) {
          final lower = p.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  double get deudaPendiente {
    return recibos.where((recibo) {
      final estado = _estado(recibo);
      return estado == 'PENDIENTE' || estado == 'VENCIDO';
    }).fold(0.0, (sum, recibo) {
      return sum + _total(recibo);
    });
  }

  int get totalSuministros => suministros.length;

  int get recibosPendientes {
    return recibos.where((recibo) => _estado(recibo) == 'PENDIENTE').length;
  }

  int get recibosVencidos {
    return recibos.where((recibo) => _estado(recibo) == 'VENCIDO').length;
  }

  double get consumoUltimoMes {
    if (recibosOrdenados.isEmpty) return 0;

    return _consumo(recibosOrdenados.first);
  }

  Map<String, dynamic>? get ultimoRecibo {
    if (recibosOrdenados.isEmpty) return null;

    return recibosOrdenados.first;
  }

  Map<String, dynamic>? get reciboPendiente {
    try {
      return recibosOrdenados.firstWhere((recibo) {
        final estado = _estado(recibo);
        return estado == 'PENDIENTE' || estado == 'VENCIDO';
      });
    } catch (_) {
      return null;
    }
  }

  void irRecibos() {
    Navigator.pushReplacementNamed(context, '/recibos');
  }

  void irPerfil() {
    Navigator.pushReplacementNamed(context, '/perfil');
  }

  void irPagar() {
    final recibo = reciboPendiente;

    if (recibo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tienes recibos pendientes para pagar.'),
          backgroundColor: Color(0xFF1F8F4D),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/pago-cip',
      arguments: recibo,
    );
  }

  void verUltimoRecibo() {
    final recibo = ultimoRecibo;

    if (recibo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aún no tienes recibos registrados.'),
          backgroundColor: Color(0xFFC77700),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/recibo-detalle',
      arguments: recibo,
    );
  }

  // Barra inferior cliente:
  // 0 = Inicio, 1 = Recibos, 2 = Pagar, 3 = Perfil.
  void _goBottomCliente(int index) {
    if (index == 0) return;

    if (index == 1) {
      irRecibos();
    }

    if (index == 2) {
      irPagar();
    }

    if (index == 3) {
      irPerfil();
    }
  }

  // Menú flotante del botón "+".
  // Este menú queda blanco para mantener el estilo claro de la app.
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
                          icon: Icons.person_rounded,
                          label: 'Perfil',
                          onTap: () {
                            Navigator.pop(context);
                            irPerfil();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.visibility_rounded,
                          label: 'Último',
                          onTap: () {
                            Navigator.pop(context);
                            verUltimoRecibo();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.lock_reset_rounded,
                          label: 'Clave',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/cambiar-password');
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

      // Necesario para que la barra inferior flotante se vea moderna.
      extendBody: true,

      bottomNavigationBar: ClienteBottomNav(
        currentIndex: 0,
        onTap: _goBottomCliente,
        onPlus: _abrirMenuCliente,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarDatos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            // Se deja más espacio inferior para que la barra no tape contenido.
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                SizedBox(height: 22),
                if (cargando) _buildLoading(),
                if (error.isNotEmpty && !cargando) _buildError(),
                if (!cargando && error.isEmpty) ...[
                  _buildWelcomeCard(),
                  SizedBox(height: 18),
                  _buildStats(),
                  SizedBox(height: 18),
                  _buildUltimoReciboCard(),
                  SizedBox(height: 24),
                  Text(
                    'Accesos rápidos',
                    style: TextStyle(
                      color: primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 14),
                  _buildQuickActions(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: secondary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            Icons.water_drop_rounded,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JASS Huacariz',
                style: TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Portal móvil del cliente',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: irPerfil,
          icon: Icon(
            Icons.account_circle_outlined,
            color: primary,
            size: 30,
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
            'Cargando información...',
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
            color: Color(0xFFD93025),
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD93025),
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

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Bienvenido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Hola, $nombreCliente',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Consulta tus recibos, suministros y pagos del servicio de agua potable.',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deuda total pendiente',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'S/ ${deudaPendiente.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '$recibosPendientes pendiente(s) · $recibosVencidos vencido(s)',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 13,
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

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.water_drop_outlined,
            label: 'Suministros',
            value: '$totalSuministros',
            subLabel: 'Asociados',
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: _StatBox(
            icon: Icons.bar_chart_rounded,
            label: 'Consumo',
            value: '${consumoUltimoMes.toStringAsFixed(2)} m³',
            subLabel: 'Último mes',
          ),
        ),
      ],
    );
  }

  Widget _buildUltimoReciboCard() {
    final recibo = ultimoRecibo;

    if (recibo == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.jassSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.jassBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: secondary,
              size: 32,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aún no tienes recibos registrados.',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final estado = _estado(recibo);

    return InkWell(
      onTap: verUltimoRecibo,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.jassSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.jassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Último recibo',
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.jassSelectedSurface,
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: secondary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _codigoRecibo(recibo),
                        style: TextStyle(
                          color: primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '${_codigoSuministro(recibo)} · ${_periodo(recibo)}',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _EstadoMiniBadge(estado: estado),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SmallInfo(
                    label: 'Consumo',
                    value: '${_consumo(recibo).toStringAsFixed(2)} m³',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _SmallInfo(
                    label: 'Total',
                    value: 'S/ ${_total(recibo).toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.receipt_long_rounded,
            label: 'Recibos',
            onTap: irRecibos,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.payments_rounded,
            label: 'Pagar',
            onTap: irPagar,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.person_rounded,
            label: 'Perfil',
            onTap: irPerfil,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subLabel;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    const Color secondary = JassColors.secondary;
    final Color muted = context.jassTextMuted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: secondary,
            size: 30,
          ),
          SizedBox(height: 18),
          Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primary,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subLabel,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  final String label;
  final String value;

  const _SmallInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    final Color muted = context.jassTextMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
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

class _EstadoMiniBadge extends StatelessWidget {
  final String estado;

  const _EstadoMiniBadge({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final upper = estado.toUpperCase();

    Color bg;
    Color text;

    if (upper == 'PAGADO') {
      bg = const Color(0xFFEAF8EF);
      text = const Color(0xFF1F8F4D);
    } else if (upper == 'VENCIDO') {
      bg = const Color(0xFFFFECEC);
      text = const Color(0xFFD93025);
    } else {
      bg = const Color(0xFFFFF3DF);
      text = const Color(0xFFC77700);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        upper,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    const Color secondary = JassColors.secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: context.jassSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.jassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: secondary,
              size: 28,
            ),
            SizedBox(height: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
