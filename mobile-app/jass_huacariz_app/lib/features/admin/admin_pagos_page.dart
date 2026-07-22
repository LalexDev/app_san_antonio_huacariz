// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations
import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/pago_service.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminPagosPage extends StatefulWidget {
  const AdminPagosPage({super.key});

  @override
  State<AdminPagosPage> createState() => _AdminPagosPageState();
}

class _AdminPagosPageState extends State<AdminPagosPage> {
  final Color secondary = JassColors.secondary;
  final PagoService pagoService = PagoService();

  List<Map<String, dynamic>> pagos = [];
  bool cargando = false;
  String error = '';
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarPagos();
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

    final text = value.toString().replaceAll(',', '.').trim();
    return double.tryParse(text) ?? 0.0;
  }

  String _codigoRecibo(Map<String, dynamic> pago) {
    final recibo = pago['recibo'];

    if (recibo is Map) {
      return _txt(
        recibo['codigoRecibo'] ?? recibo['codigo'] ?? recibo['numeroRecibo'],
        'RECIBO',
      );
    }

    return _txt(
      pago['codigoRecibo'] ??
          pago['reciboCodigo'] ??
          pago['numeroRecibo'] ??
          pago['codigo'],
      'RECIBO',
    );
  }

  String _codigoOperacion(Map<String, dynamic> pago) {
    return _txt(
      pago['codigoOperacion'] ??
          pago['operacion'] ??
          pago['numeroOperacion'] ??
          pago['referencia'],
      'SIN OPERACIÓN',
    );
  }

  String _metodoPago(Map<String, dynamic> pago) {
    return _txt(
      pago['metodoPago'] ??
          pago['metodo'] ??
          pago['formaPago'] ??
          pago['tipoPago'],
      'Sin datos',
    );
  }

  double _monto(Map<String, dynamic> pago) {
    return _num(
      pago['monto'] ??
          pago['montoPagado'] ??
          pago['total'] ??
          pago['importe'] ??
          pago['totalPagado'],
    );
  }

  String _fecha(Map<String, dynamic> pago) {
    return _txt(
      pago['fechaPago'] ??
          pago['fecha'] ??
          pago['fechaRegistro'] ??
          pago['createdAt'],
      '-',
    );
  }

  String _cliente(Map<String, dynamic> pago) {
    return _txt(
      pago['nombreCliente'] ??
          pago['cliente'] ??
          pago['titular'] ??
          pago['usuario'],
      '-',
    );
  }

  String _suministro(Map<String, dynamic> pago) {
    return _txt(
      pago['codigoSuministro'] ??
          pago['suministroCodigo'] ??
          pago['numeroSuministro'],
      '-',
    );
  }

  bool _esPagoDelMes(Map<String, dynamic> pago) {
    final fechaTexto = _fecha(pago);
    final fecha = DateTime.tryParse(fechaTexto);

    if (fecha == null) return false;

    final now = DateTime.now();

    return fecha.year == now.year && fecha.month == now.month;
  }

  double get montoRecaudado {
    return pagos.fold(0.0, (sum, pago) => sum + _monto(pago));
  }

  int get pagosDelMes {
    return pagos.where(_esPagoDelMes).length;
  }

  String get metodoPrincipal {
    if (pagos.isEmpty) return 'Sin datos';

    final conteo = <String, int>{};

    for (final pago in pagos) {
      final metodo = _metodoPago(pago);
      conteo[metodo] = (conteo[metodo] ?? 0) + 1;
    }

    final ordenado = conteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ordenado.isEmpty ? 'Sin datos' : ordenado.first.key;
  }

  Map<String, int> get conteoMetodos {
    final data = <String, int>{};

    for (final pago in pagos) {
      final metodo = _metodoPago(pago);
      data[metodo] = (data[metodo] ?? 0) + 1;
    }

    return data;
  }

  List<Map<String, dynamic>> get pagosFiltrados {
    final query = busqueda.trim().toLowerCase();

    if (query.isEmpty) return pagos;

    return pagos.where((pago) {
      final texto = '''
      ${_codigoRecibo(pago)}
      ${_codigoOperacion(pago)}
      ${_metodoPago(pago)}
      ${_cliente(pago)}
      ${_suministro(pago)}
      ${_fecha(pago)}
      ${_monto(pago)}
      '''
          .toLowerCase();

      return texto.contains(query);
    }).toList();
  }

  Future<void> cargarPagos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await pagoService.listarPagos();

      if (!mounted) return;

      setState(() {
        pagos = data;
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

  void limpiarFiltros() {
    setState(() {
      busqueda = '';
    });
  }

  void _volverDashboard() {
    Navigator.pushReplacementNamed(context, '/admin-dashboard');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: AdminBottomNav(
        // Pagos se abre desde el menú "+", por eso no se marca
        // ninguna de las cuatro opciones principales.
        currentIndex: -1,
        onTap: _go,
        onPlus: () {
          showAdminQuickMenu(
            context: context,
            onRefresh: cargarPagos,
          );
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarPagos,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 16),
                if (cargando)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (error.isNotEmpty && !cargando)
                  _ErrorBox(
                    error: error,
                    onRetry: cargarPagos,
                  ),
                if (!cargando && error.isEmpty) ...[
                  _buildStats(),
                  SizedBox(height: 18),
                  _buildMetodos(),
                  SizedBox(height: 18),
                  _buildSearch(),
                  SizedBox(height: 18),
                  _buildListado(),
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
          ),
          child: IconButton(
            onPressed: _volverDashboard,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.jassTextPrimary,
            ),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pagos / Recaudación',
                style: TextStyle(
                  color: secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pagos',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Consulta pagos registrados y recaudación del servicio.',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: cargarPagos,
          icon: Icon(
            Icons.refresh_rounded,
            color: context.jassTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.payments_rounded,
                label: 'Pagos totales',
                value: '${pagos.length}',
                subtitle: 'Pagos registrados',
                selected: true,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.savings_rounded,
                label: 'Monto recaudado',
                value: 'S/ ${montoRecaudado.toStringAsFixed(2)}',
                subtitle: 'Total acumulado',
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month_rounded,
                label: 'Pagos del mes',
                value: '$pagosDelMes',
                subtitle: 'Mes actual',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_rounded,
                label: 'Método principal',
                value: metodoPrincipal,
                subtitle: 'Método más usado',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetodos() {
    final metodos = conteoMetodos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Métodos de pago',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Distribución de pagos por método de cobranza.',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          if (metodos.isEmpty)
            Text(
              'Sin métodos registrados.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...metodos.map((entry) {
              return _MetodoLine(
                metodo: entry.key,
                cantidad: entry.value,
                total: pagos.length,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) {
              setState(() {
                busqueda = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar por recibo, método, operación o fecha...',
              prefixIcon: Icon(Icons.search_rounded),
              filled: true,
              fillColor: context.jassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: limpiarFiltros,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.jassSurface,
            foregroundColor: context.jassTextPrimary,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.jassBorder),
            ),
          ),
          child: Text(
            'Limpiar',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildListado() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pagos registrados',
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${pagosFiltrados.length} resultado(s)',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          if (pagosFiltrados.isEmpty)
            Text(
              'No hay pagos para mostrar.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...pagosFiltrados.map((pago) {
              return _PagoCard(
                recibo: _codigoRecibo(pago),
                metodo: _metodoPago(pago),
                operacion: _codigoOperacion(pago),
                monto: _monto(pago),
                fecha: _fecha(pago),
                cliente: _cliente(pago),
                suministro: _suministro(pago),
              );
            }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final bool selected;

  _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? JassColors.primary : context.jassSurface;
    final text = selected ? Colors.white : context.jassTextPrimary;
    final sub = selected ? Color(0xFFE7F8FF) : context.jassTextMuted;

    return Container(
  constraints: BoxConstraints(
    minHeight: 118,
  ),
  padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: selected ? Colors.white : JassColors.secondary),
          SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sub,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sub,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetodoLine extends StatelessWidget {
  final String metodo;
  final int cantidad;
  final int total;

  _MetodoLine({
    required this.metodo,
    required this.cantidad,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = total <= 0 ? 0.0 : cantidad / total;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metodo,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: porcentaje,
            minHeight: 7,
            borderRadius: BorderRadius.circular(100),
          ),
          SizedBox(height: 6),
          Text(
            '$cantidad pago(s)',
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

class _PagoCard extends StatelessWidget {
  final String recibo;
  final String metodo;
  final String operacion;
  final double monto;
  final String fecha;
  final String cliente;
  final String suministro;

  _PagoCard({
    required this.recibo,
    required this.metodo,
    required this.operacion,
    required this.monto,
    required this.fecha,
    required this.cliente,
    required this.suministro,
  });

  @override
  Widget build(BuildContext context) {
    final Color secondary = JassColors.secondary;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: Text(
                  recibo,
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'S/ ${monto.toStringAsFixed(2)}',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _Line(label: 'Método', value: metodo),
          _Line(label: 'Operación', value: operacion),
          _Line(label: 'Fecha', value: fecha),
          _Line(label: 'Cliente', value: cliente),
          _Line(label: 'Suministro', value: suministro),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;

  _Line({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5),
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: context.jassTextPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  _ErrorBox({
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
