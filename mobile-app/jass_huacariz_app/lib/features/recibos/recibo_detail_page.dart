import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../shared/widgets/cliente_bottom_nav.dart';

class ReciboDetailPage extends StatefulWidget {
  const ReciboDetailPage({super.key});

  @override
  State<ReciboDetailPage> createState() => _ReciboDetailPageState();
}

class _ReciboDetailPageState extends State<ReciboDetailPage> {
  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;
  Color get background => context.jassBackground;
  Color get muted => context.jassTextMuted;
  static const Color danger = JassColors.danger;
  static const Color success = JassColors.success;
  static const Color warning = JassColors.warning;

  Map<String, dynamic> _getRecibo(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      return args;
    }

    if (args is Map) {
      return Map<String, dynamic>.from(args);
    }

    return {};
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
          recibo['codigoSuministroRecibo'] ??
          recibo['numeroSuministro'] ??
          recibo['suministro'],
      'SIN-SUMINISTRO',
    );
  }

  String _direccion(Map<String, dynamic> recibo) {
    return _texto(
      recibo['direccionSuministro'] ??
          recibo['direccion'] ??
          recibo['direccionCliente'],
      'Dirección no registrada',
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

  String _estado(Map<String, dynamic> recibo) {
    return _texto(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    ).toUpperCase();
  }

  double _lecturaAnterior(Map<String, dynamic> recibo) {
    return _numero(
      recibo['lecturaAnterior'] ??
          recibo['lecturaAnteriorM3'] ??
          recibo['lecturaInicial'] ??
          0,
    );
  }

  double _lecturaActual(Map<String, dynamic> recibo) {
    return _numero(
      recibo['lecturaActual'] ??
          recibo['lecturaActualM3'] ??
          recibo['lecturaFinal'] ??
          0,
    );
  }

  double _consumo(Map<String, dynamic> recibo) {
    return _numero(
      recibo['consumoM3'] ?? recibo['consumo'] ?? recibo['consumoMes'] ?? 0,
    );
  }

  double _cargoAgua(Map<String, dynamic> recibo) {
    return _numero(
      recibo['cargoAgua'] ??
          recibo['montoAgua'] ??
          recibo['importeAgua'] ??
          recibo['subtotal'] ??
          0,
    );
  }

  double _cargoMantenimiento(Map<String, dynamic> recibo) {
    return _numero(
      recibo['cargoMantenimiento'] ??
          recibo['mantenimiento'] ??
          recibo['montoMantenimiento'] ??
          0,
    );
  }

  double _cargoOtros(Map<String, dynamic> recibo) {
    return _numero(
      recibo['otrosCargos'] ??
          recibo['cargoOtros'] ??
          recibo['montoOtros'] ??
          0,
    );
  }

  double _mora(Map<String, dynamic> recibo) {
    return _numero(
      recibo['mora'] ?? recibo['cargoMora'] ?? recibo['montoMora'] ?? 0,
    );
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

  String _fechaEmision(Map<String, dynamic> recibo) {
    return _texto(
      recibo['fechaEmision'] ?? recibo['emision'],
      '-',
    );
  }

  String _fechaVencimiento(Map<String, dynamic> recibo) {
    return _texto(
      recibo['fechaVencimiento'] ?? recibo['vencimiento'],
      '-',
    );
  }

  bool _puedePagar(Map<String, dynamic> recibo) {
    final estado = _estado(recibo);

    return estado == 'PENDIENTE' || estado == 'VENCIDO';
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

  void _irPagar(Map<String, dynamic> recibo) {
    if (!_puedePagar(recibo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Este recibo no está pendiente de pago.'),
          backgroundColor: success,
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

  void _verPdf(Map<String, dynamic> recibo) {
    Navigator.pushNamed(
      context,
      '/pdf-viewer',
      arguments: recibo,
    );
  }

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _irRecibos();
    }
  }

  // Barra inferior cliente:
  // 0 = Inicio, 1 = Recibos, 2 = Pagar, 3 = Perfil.
  void _goBottomCliente(int index) {
    final recibo = _getRecibo(context);

    if (index == 0) {
      _irHome();
    }

    if (index == 1) {
      _irRecibos();
    }

    if (index == 2) {
      _irPagar(recibo);
    }

    if (index == 3) {
      _irPerfil();
    }
  }

  void _abrirMenuCliente() {
    final recibo = _getRecibo(context);

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
                            _irPagar(recibo);
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.picture_as_pdf_rounded,
                          label: 'PDF',
                          onTap: () {
                            Navigator.pop(context);
                            _verPdf(recibo);
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
    final recibo = _getRecibo(context);

    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: ClienteBottomNav(
        currentIndex: 1,
        onTap: _goBottomCliente,
        onPlus: _abrirMenuCliente,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 18),
              _buildMainCard(recibo),
              SizedBox(height: 18),
              _buildLecturasCard(recibo),
              SizedBox(height: 18),
              _buildMontosCard(recibo),
              SizedBox(height: 18),
              _buildFechasCard(recibo),
              SizedBox(height: 22),
              _buildActions(recibo),
            ],
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
                'Detalle de recibo',
                style: TextStyle(
                  color: primary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard(Map<String, dynamic> recibo) {
    final estado = _estado(recibo);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _codigoRecibo(recibo),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _EstadoBadge(estado: estado),
            ],
          ),
          SizedBox(height: 18),
          _HeroLine(
            label: 'Suministro',
            value: _codigoSuministro(recibo),
          ),
          _HeroLine(
            label: 'Dirección',
            value: _direccion(recibo),
          ),
          _HeroLine(
            label: 'Periodo',
            value: _periodo(recibo),
          ),
          SizedBox(height: 18),
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
                  'Total del recibo',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'S/ ${_total(recibo).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturasCard(Map<String, dynamic> recibo) {
    return _SectionCard(
      title: 'Lecturas y consumo',
      icon: Icons.speed_rounded,
      children: [
        _InfoRow(
          label: 'Lectura anterior',
          value: '${_lecturaAnterior(recibo).toStringAsFixed(3)} m³',
        ),
        _InfoRow(
          label: 'Lectura actual',
          value: '${_lecturaActual(recibo).toStringAsFixed(3)} m³',
        ),
        _InfoRow(
          label: 'Consumo facturado',
          value: '${_consumo(recibo).toStringAsFixed(2)} m³',
          highlight: true,
        ),
      ],
    );
  }

  Widget _buildMontosCard(Map<String, dynamic> recibo) {
    return _SectionCard(
      title: 'Detalle de cobros',
      icon: Icons.account_balance_wallet_rounded,
      children: [
        _InfoRow(
          label: 'Cargo por agua',
          value: 'S/ ${_cargoAgua(recibo).toStringAsFixed(2)}',
        ),
        _InfoRow(
          label: 'Mantenimiento',
          value: 'S/ ${_cargoMantenimiento(recibo).toStringAsFixed(2)}',
        ),
        _InfoRow(
          label: 'Otros cargos',
          value: 'S/ ${_cargoOtros(recibo).toStringAsFixed(2)}',
        ),
        _InfoRow(
          label: 'Mora',
          value: 'S/ ${_mora(recibo).toStringAsFixed(2)}',
        ),
        Divider(height: 22),
        _InfoRow(
          label: 'Total',
          value: 'S/ ${_total(recibo).toStringAsFixed(2)}',
          highlight: true,
        ),
      ],
    );
  }

  Widget _buildFechasCard(Map<String, dynamic> recibo) {
    return _SectionCard(
      title: 'Fechas',
      icon: Icons.calendar_month_rounded,
      children: [
        _InfoRow(
          label: 'Fecha de emisión',
          value: _fechaEmision(recibo),
        ),
        _InfoRow(
          label: 'Fecha de vencimiento',
          value: _fechaVencimiento(recibo),
        ),
        _InfoRow(
          label: 'Estado',
          value: _estado(recibo),
          highlight: true,
        ),
      ],
    );
  }

  Widget _buildActions(Map<String, dynamic> recibo) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _puedePagar(recibo) ? () => _irPagar(recibo) : null,
            icon: Icon(Icons.payments_rounded),
            label: Text(
              _puedePagar(recibo) ? 'Pagar recibo' : 'Recibo pagado',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: success.withValues(alpha: 0.60),
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
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () => _verPdf(recibo),
            icon: Icon(Icons.picture_as_pdf_rounded),
            label: Text(
              'Ver PDF del recibo',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              backgroundColor: context.jassSurface,
              side: BorderSide(
                color: context.jassBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroLine extends StatelessWidget {
  final String label;
  final String value;

  const _HeroLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          SizedBox(width: 12),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    const Color secondary = JassColors.secondary;

    return Container(
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
            color: JassColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: secondary,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    const Color secondary = JassColors.secondary;
    final Color muted = context.jassTextMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: highlight ? context.jassSelectedSurface : context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: highlight ? secondary : primary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
