// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations
import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/cliente_service.dart';
import '../../core/services/recibo_service.dart';
import '../../core/services/pago_service.dart';
import '../../core/services/lectura_admin_service.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminReportesPage extends StatefulWidget {
  const AdminReportesPage({super.key});

  @override
  State<AdminReportesPage> createState() => _AdminReportesPageState();
}

class _AdminReportesPageState extends State<AdminReportesPage> {
  final Color secondary = JassColors.secondary;
  final ClienteService clienteService = ClienteService();
  final ReciboService reciboService = ReciboService();
  final PagoService pagoService = PagoService();
  final LecturaAdminService lecturaAdminService = LecturaAdminService();

  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> recibos = [];
  List<Map<String, dynamic>> pagos = [];
  List<Map<String, dynamic>> lecturas = [];

  bool cargando = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarReportes();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  bool _bool(dynamic value) {
    if (value is bool) return value;
    final text = value.toString().toLowerCase().trim();
    return text == 'true' || text == 'activo' || text == '1';
  }

  String _estadoRecibo(Map<String, dynamic> recibo) {
    return _txt(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    ).toUpperCase();
  }

  double _totalRecibo(Map<String, dynamic> recibo) {
    return _num(
      recibo['total'] ?? recibo['montoTotal'] ?? recibo['importeTotal'] ?? 0,
    );
  }

  double _consumoRecibo(Map<String, dynamic> recibo) {
    return _num(
      recibo['consumoM3'] ?? recibo['consumo'] ?? recibo['consumoMes'] ?? 0,
    );
  }

  double _montoPago(Map<String, dynamic> pago) {
    return _num(
      pago['monto'] ?? pago['total'] ?? pago['importe'] ?? pago['montoPago'] ?? 0,
    );
  }

  DateTime? _fecha(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return null;

    return DateTime.tryParse(text);
  }

  Future<void> cargarReportes() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final clientesData = await clienteService.listarClientes();
      final recibosData = await reciboService.listarRecibosAdmin();
      final pagosData = await pagoService.listarPagos();

      List<Map<String, dynamic>> lecturasData = [];

      try {
        lecturasData = await lecturaAdminService.listarHistorialLecturas();
      } catch (_) {
        lecturasData = [];
      }

      if (!mounted) return;

      setState(() {
        clientes = clientesData;
        recibos = recibosData;
        pagos = pagosData;
        lecturas = lecturasData;
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

  int get clientesActivos {
    return clientes.where((cliente) => _bool(cliente['estado'])).length;
  }

  int get suministrosActivos {
    int total = 0;

    for (final cliente in clientes) {
      final suministros = cliente['suministros'];

      if (suministros is List) {
        total += suministros.where((item) {
          final suministro = Map<String, dynamic>.from(item as Map);
          return _bool(suministro['estado']);
        }).length;
      }
    }

    return total;
  }

  int get recibosEmitidos {
    return recibos.length;
  }

  int get recibosPendientes {
    return recibos.where((recibo) {
      return _estadoRecibo(recibo) == 'PENDIENTE';
    }).length;
  }

  int get recibosVencidos {
    return recibos.where((recibo) {
      return _estadoRecibo(recibo) == 'VENCIDO';
    }).length;
  }

  int get recibosPagados {
    return recibos.where((recibo) {
      return _estadoRecibo(recibo) == 'PAGADO';
    }).length;
  }

  double get deudaPendiente {
    return recibos.where((recibo) {
      final estado = _estadoRecibo(recibo);
      return estado == 'PENDIENTE' || estado == 'VENCIDO';
    }).fold(0.0, (sum, recibo) {
      return sum + _totalRecibo(recibo);
    });
  }

  double get carteraVencida {
    return recibos.where((recibo) {
      return _estadoRecibo(recibo) == 'VENCIDO';
    }).fold(0.0, (sum, recibo) {
      return sum + _totalRecibo(recibo);
    });
  }

  double get recaudacionTotal {
    return pagos.fold(0.0, (sum, pago) {
      return sum + _montoPago(pago);
    });
  }

  double get recaudacionMes {
    final now = DateTime.now();

    return pagos.where((pago) {
      final fecha = _fecha(pago['fechaPago'] ?? pago['fecha'] ?? pago['createdAt']);

      if (fecha == null) return false;

      return fecha.year == now.year && fecha.month == now.month;
    }).fold(0.0, (sum, pago) {
      return sum + _montoPago(pago);
    });
  }

  double get consumoTotalM3 {
    return recibos.fold(0.0, (sum, recibo) {
      return sum + _consumoRecibo(recibo);
    });
  }

  double get consumoMesM3 {
    final now = DateTime.now();

    return recibos.where((recibo) {
      final anio = int.tryParse('${recibo['anio'] ?? 0}') ?? 0;
      final mes = int.tryParse('${recibo['mes'] ?? 0}') ?? 0;

      return anio == now.year && mes == now.month;
    }).fold(0.0, (sum, recibo) {
      return sum + _consumoRecibo(recibo);
    });
  }

  int get lecturasRegistradas {
    return lecturas.length;
  }

  double get porcentajePagados {
    if (recibos.isEmpty) return 0;
    return (recibosPagados / recibos.length) * 100;
  }

  void _go(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    }

    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/admin-clientes');
    }

    if (index == 2) {
      Navigator.pushReplacementNamed(context, '/admin-tarifas');
    }

    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/admin-recibos');
    }
  }


  void _abrirMenuAdmin() {
    showAdminQuickMenu(
      context: context,
      onRefresh: cargarReportes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: AdminBottomNav(
        currentIndex: -1,
        onTap: _go,
        onPlus: _abrirMenuAdmin,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarReportes,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22, 22, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 18),
                if (cargando)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (error.isNotEmpty && !cargando)
                  _Error(
                    error: error,
                    onRetry: cargarReportes,
                  ),
                if (!cargando && error.isEmpty) ...[
                  _buildResumenPrincipal(),
                  SizedBox(height: 18),
                  _buildIndicadoresGrid(),
                  SizedBox(height: 18),
                  _buildEstadoRecibos(),
                  SizedBox(height: 18),
                  _buildOperativo(),
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
                'Panel administrativo',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Reportes',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: cargarReportes,
          icon: Icon(
            Icons.refresh_rounded,
            color: context.jassTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildResumenPrincipal() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.jassTextPrimary,
            JassColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen financiero',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'S/ ${recaudacionTotal.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Recaudación total registrada · Este mes: S/ ${recaudacionMes.toStringAsFixed(2)}',
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

  Widget _buildIndicadoresGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 1.18,
      children: [
        _ReportCard(
          icon: Icons.groups_rounded,
          label: 'Clientes activos',
          value: '$clientesActivos',
          subtitle: 'Usuarios del sistema',
        ),
        _ReportCard(
          icon: Icons.water_drop_rounded,
          label: 'Suministros',
          value: '$suministrosActivos',
          subtitle: 'Conexiones activas',
        ),
        _ReportCard(
          icon: Icons.receipt_long_rounded,
          label: 'Recibos emitidos',
          value: '$recibosEmitidos',
          subtitle: 'Total generado',
        ),
        _ReportCard(
          icon: Icons.warning_amber_rounded,
          label: 'Cartera vencida',
          value: 'S/ ${carteraVencida.toStringAsFixed(2)}',
          subtitle: 'Recibos vencidos',
        ),
        _ReportCard(
          icon: Icons.payments_rounded,
          label: 'Deuda pendiente',
          value: 'S/ ${deudaPendiente.toStringAsFixed(2)}',
          subtitle: 'Pendiente + vencido',
        ),
        _ReportCard(
          icon: Icons.speed_rounded,
          label: 'Consumo total',
          value: '${consumoTotalM3.toStringAsFixed(0)} m³',
          subtitle: 'Consumo facturado',
        ),
      ],
    );
  }

  Widget _buildEstadoRecibos() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
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
            'Estado de recibos',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          _ProgressLine(
            label: 'Pagados',
            value: recibosPagados,
            total: recibosEmitidos,
            color: JassColors.success,
          ),
          _ProgressLine(
            label: 'Pendientes',
            value: recibosPendientes,
            total: recibosEmitidos,
            color: JassColors.warning,
          ),
          _ProgressLine(
            label: 'Vencidos',
            value: recibosVencidos,
            total: recibosEmitidos,
            color: JassColors.danger,
          ),
          SizedBox(height: 12),
          Text(
            'Tasa de pago: ${porcentajePagados.toStringAsFixed(1)}%',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperativo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
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
            'Indicadores operativos',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          _SimpleLine(
            label: 'Lecturas registradas',
            value: '$lecturasRegistradas',
          ),
          _SimpleLine(
            label: 'Consumo del mes',
            value: '${consumoMesM3.toStringAsFixed(0)} m³',
          ),
          _SimpleLine(
            label: 'Pagos registrados',
            value: '${pagos.length}',
          ),
          _SimpleLine(
            label: 'Recaudación del mes',
            value: 'S/ ${recaudacionMes.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  _ReportCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final Color secondary = JassColors.secondary;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: secondary,
            size: 30,
          ),
          Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  _ProgressLine({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : value / total;

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$value / $total',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(100),
            backgroundColor: context.jassSurfaceAlt,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _SimpleLine extends StatelessWidget {
  final String label;
  final String value;

  _SimpleLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 10,
      ),
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
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  _Error({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: JassColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
