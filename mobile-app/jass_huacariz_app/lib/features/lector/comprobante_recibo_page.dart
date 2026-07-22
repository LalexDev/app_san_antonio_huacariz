import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import '../../shared/widgets/admin_bottom_nav.dart';
import '../../shared/widgets/lector_bottom_nav.dart';

class ComprobanteReciboPage extends StatefulWidget {
  final bool modoAdmin;

  const ComprobanteReciboPage({
    super.key,
    this.modoAdmin = false,
  });

  @override
  State<ComprobanteReciboPage> createState() =>
      _ComprobanteReciboPageState();
}

class _ComprobanteReciboPageState extends State<ComprobanteReciboPage> {
  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;
  Color get background => context.jassBackground;
  Color get muted => context.jassTextMuted;

  Map<String, dynamic> comprobante = {};
  String mensajeServidor = 'Lectura registrada correctamente.';
  bool cargadoArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (cargadoArgs) return;
    cargadoArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      _cargarArgumentos(args);
    } else if (args is Map) {
      _cargarArgumentos(Map<String, dynamic>.from(args));
    }
  }

  void _cargarArgumentos(Map<String, dynamic> args) {
    mensajeServidor = _txt(
      args['mensaje'] ?? args['message'],
      'Lectura registrada correctamente.',
    );

    final recibo = args['recibo'];

    if (recibo is Map<String, dynamic>) {
      comprobante = {
        ...args,
        ...recibo,
      };
      return;
    }

    if (recibo is Map) {
      comprobante = {
        ...args,
        ...Map<String, dynamic>.from(recibo),
      };
      return;
    }

    comprobante = args;
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  double _num(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) return value.toDouble();

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return 0.0;

    return double.tryParse(text) ?? 0.0;
  }

  int _int(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? fallback;
  }

  String _codigoRecibo() {
    return _txt(
      comprobante['codigoRecibo'] ??
          comprobante['numeroRecibo'] ??
          comprobante['codigo'],
      'REC-GENERADO',
    );
  }

  String _codigoSuministro() {
    return _txt(
      comprobante['codigoSuministro'] ??
          comprobante['suministroCodigo'] ??
          comprobante['numeroSuministro'],
      'SIN-CÓDIGO',
    );
  }

  String _titular() {
    return _txt(
      comprobante['titular'] ??
          comprobante['cliente'] ??
          comprobante['nombreCliente'] ??
          comprobante['nombres'] ??
          comprobante['usuario'],
      'Usuario del servicio',
    );
  }

  String _direccion() {
    return _txt(
      comprobante['direccionSuministro'] ??
          comprobante['direccion'] ??
          comprobante['direccionCliente'],
      'Dirección no registrada',
    );
  }

  String _sector() {
    return _txt(
      comprobante['nombreSector'] ??
          comprobante['sector'] ??
          comprobante['sectorNombre'],
      'Huacariz',
    );
  }

  double _lecturaAnterior() {
    return _num(
      comprobante['lecturaAnterior'] ??
          comprobante['ultimaLectura'] ??
          comprobante['lecturaInicial'] ??
          0,
    );
  }

  double _lecturaActual() {
    return _num(
      comprobante['lecturaActual'] ??
          comprobante['lecturaNueva'] ??
          comprobante['actual'] ??
          0,
    );
  }

  double _consumo() {
    final consumo = _num(
      comprobante['consumoM3'] ??
          comprobante['consumo'] ??
          comprobante['consumoMes'],
    );

    if (consumo > 0) return consumo;

    final calculado = _lecturaActual() - _lecturaAnterior();

    return calculado < 0 ? 0 : calculado;
  }

  double _subtotalAgua() {
    return _num(
      comprobante['subtotalAgua'] ??
          comprobante['montoAgua'] ??
          comprobante['importeAgua'] ??
          comprobante['agua'] ??
          comprobante['volumenAgua'] ??
          0,
    );
  }

  double _mantenimiento() {
    return _num(
      comprobante['cargoMantenimiento'] ??
          comprobante['mantenimiento'] ??
          comprobante['montoMantenimiento'] ??
          0,
    );
  }

  double _lector() {
    return _num(
      comprobante['cargoLector'] ??
          comprobante['pagoLector'] ??
          comprobante['pagoLecturador'] ??
          comprobante['montoLecturador'] ??
          comprobante['lector'] ??
          0,
    );
  }

  double _otros() {
    return _num(
      comprobante['cargoOtros'] ??
          comprobante['otrosCargos'] ??
          comprobante['otros'] ??
          0,
    );
  }

  double _mora() {
    return _num(
      comprobante['mora'] ??
          comprobante['montoMora'] ??
          0,
    );
  }

  double _total() {
    final totalBackend = _num(
      comprobante['total'] ??
          comprobante['montoTotal'] ??
          comprobante['importeTotal'] ??
          comprobante['totalPagar'],
    );

    if (totalBackend > 0) return totalBackend;

    return _subtotalAgua() +
        _mantenimiento() +
        _lector() +
        _otros() +
        _mora();
  }

  String _periodo() {
    final anio = _int(comprobante['anio'], DateTime.now().year);
    final mes = _int(comprobante['mes'], DateTime.now().month);

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

    final index = (mes - 1).clamp(0, 11);

    return '${meses[index]} $anio';
  }

  String _fechaEmision() {
    return _txt(
      comprobante['fechaEmision'] ??
          comprobante['fechaLectura'] ??
          comprobante['createdAt'],
      _fechaActualTexto(),
    );
  }

  String _fechaVencimiento() {
    return _txt(
      comprobante['fechaVencimiento'] ??
          comprobante['vencimiento'],
      '-',
    );
  }

  String _observacion() {
    return _txt(
      comprobante['observacion'],
      'Sin observaciones registradas.',
    );
  }

  String _fechaActualTexto() {
    final now = DateTime.now();

    final dia = now.day.toString().padLeft(2, '0');
    final mes = now.month.toString().padLeft(2, '0');
    final anio = now.year.toString();

    return '$anio-$mes-$dia';
  }

  void _nuevaLectura() {
    Navigator.pushReplacementNamed(
      context,
      widget.modoAdmin
          ? '/admin-buscar-suministro'
          : '/buscar-suministro',
    );
  }

  void _volverInicio() {
    Navigator.pushReplacementNamed(
      context,
      widget.modoAdmin
          ? '/admin-dashboard'
          : '/lector-home',
    );
  }

  void _verHistorial() {
    Navigator.pushReplacementNamed(
      context,
      widget.modoAdmin
          ? '/admin-historial-lecturas'
          : '/historial-lecturas',
    );
  }

  void _goBottomAdmin(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/admin-clientes');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/admin-tarifas');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/admin-recibos');
    }
  }

  void _abrirMenuAdmin() {
    showAdminQuickMenu(context: context);
  }

  void _goBottomLector(int index) {
    if (index == 0) {
      _volverInicio();
    } else if (index == 1) {
      _nuevaLectura();
    } else if (index == 2) {
      Navigator.pushNamed(context, '/qr-scanner');
    } else if (index == 3) {
      _verHistorial();
    }
  }

  void _abrirMenuLector() {
    showLectorQuickMenu(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: widget.modoAdmin
          ? AdminBottomNav(
              currentIndex: -1,
              onTap: _goBottomAdmin,
              onPlus: _abrirMenuAdmin,
            )
          : LectorBottomNav(
              currentIndex: -1,
              onTap: _goBottomLector,
              onPlus: _abrirMenuLector,
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (comprobante['origenOffline'] == true ||
                  comprobante['montoProvisional'] == true) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2D8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        color: Color(0xFF9A6500),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Recibo provisional pendiente de sincronización. El monto oficial será confirmado por el servidor.',
                          style: TextStyle(
                            color: Color(0xFF9A6500),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 18),
              _buildSuccessCard(),
              SizedBox(height: 18),
              _buildClienteCard(),
              SizedBox(height: 18),
              _buildLecturasCard(),
              SizedBox(height: 18),
              _buildFacturacionCard(),
              SizedBox(height: 18),
              _buildTotalCard(),
              SizedBox(height: 18),
              _buildObservacionCard(),
              SizedBox(height: 22),
              _buildActions(),
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
          ),
          child: IconButton(
            onPressed: _volverInicio,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: primary,
            ),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.modoAdmin
                    ? 'Panel del administrador'
                    : 'Módulo lecturador',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Comprobante',
                style: TextStyle(
                  color: primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard() {
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
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 28,
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Lectura registrada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '$mensajeServidor\nRecibo: ${_codigoRecibo()}\nPeriodo: ${_periodo()}',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard() {
    return _SectionCard(
      title: 'Datos del suministro',
      children: [
        _InfoLine(label: 'Código suministro', value: _codigoSuministro()),
        _InfoLine(label: 'Titular', value: _titular()),
        _InfoLine(label: 'Dirección', value: _direccion()),
        _InfoLine(label: 'Sector', value: _sector()),
        _InfoLine(label: 'Periodo', value: _periodo()),
        _InfoLine(label: 'Emisión', value: _fechaEmision()),
        _InfoLine(label: 'Vencimiento', value: _fechaVencimiento()),
      ],
    );
  }

  Widget _buildLecturasCard() {
    return _SectionCard(
      title: 'Lecturas y consumo',
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniValue(
                label: 'Anterior',
                value: _lecturaAnterior().toStringAsFixed(0),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MiniValue(
                label: 'Actual',
                value: _lecturaActual().toStringAsFixed(0),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MiniValue(
                label: 'Consumo',
                value: '${_consumo().toStringAsFixed(2)} m³',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFacturacionCard() {
    return _SectionCard(
      title: 'Detalle de facturación',
      children: [
        _InfoLine(
          label: 'Volumen de agua potable',
          value: 'S/ ${_subtotalAgua().toStringAsFixed(2)}',
        ),
        _InfoLine(
          label: 'Mantenimiento',
          value: 'S/ ${_mantenimiento().toStringAsFixed(2)}',
        ),
        _InfoLine(
          label: 'Pago al lecturador',
          value: 'S/ ${_lector().toStringAsFixed(2)}',
        ),
        _InfoLine(
          label: 'Otros cargos',
          value: 'S/ ${_otros().toStringAsFixed(2)}',
        ),
        _InfoLine(
          label: 'Mora',
          value: 'S/ ${_mora().toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3DF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD899),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total generado',
              style: TextStyle(
                color: JassColors.primary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            'S/ ${_total().toStringAsFixed(2)}',
            style: TextStyle(
              color: JassColors.primary,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservacionCard() {
    return _SectionCard(
      title: 'Observación',
      children: [
        Text(
          _observacion(),
          style: TextStyle(
            color: muted,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _nuevaLectura,
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: Text(
              'Registrar nueva lectura',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _verHistorial,
            icon: Icon(Icons.history_rounded),
            label: Text(
              'Ver historial de lecturas',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: context.jassBorder),
              backgroundColor: context.jassSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    final Color muted = context.jassTextMuted;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.jassBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
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
}

class _MiniValue extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValue({
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
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
