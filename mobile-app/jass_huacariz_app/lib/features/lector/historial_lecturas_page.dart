import 'package:flutter/material.dart';

import '../../core/services/lectura_admin_service.dart';
import '../../core/services/lectura_offline_service.dart';
import '../../core/services/sincronizacion_lecturas_service.dart';
import '../../shared/theme/jass_colors.dart';
import '../../shared/widgets/admin_bottom_nav.dart';
import '../../shared/widgets/lector_bottom_nav.dart';

class HistorialLecturasPage extends StatefulWidget {
  final bool modoAdmin;

  const HistorialLecturasPage({
    super.key,
    this.modoAdmin = false,
  });

  @override
  State<HistorialLecturasPage> createState() =>
      _HistorialLecturasPageState();
}

class _HistorialLecturasPageState extends State<HistorialLecturasPage> {
  final LecturaAdminService lecturaService = LecturaAdminService();
  final LecturaOfflineService offlineService = LecturaOfflineService();
  final SincronizacionLecturasService sincronizacionService =
      SincronizacionLecturasService();
  final TextEditingController buscarController = TextEditingController();

  List<Map<String, dynamic>> lecturas = [];

  bool cargando = false;
  String error = '';
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarHistorial();
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
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

  String _codigoSuministro(Map<String, dynamic> lectura) {
    return _txt(
      lectura['codigoSuministro'] ??
          lectura['suministroCodigo'] ??
          lectura['codigo'] ??
          lectura['numeroSuministro'],
      'SIN-CÓDIGO',
    );
  }

  String _cliente(Map<String, dynamic> lectura) {
    return _txt(
      lectura['titular'] ??
          lectura['cliente'] ??
          lectura['nombreCliente'] ??
          lectura['nombres'] ??
          lectura['usuario'],
      'Usuario del servicio',
    );
  }

  String _direccion(Map<String, dynamic> lectura) {
    return _txt(
      lectura['direccionSuministro'] ??
          lectura['direccion'] ??
          lectura['direccionCliente'],
      'Dirección no registrada',
    );
  }

  double _lecturaAnterior(Map<String, dynamic> lectura) {
    return _num(
      lectura['lecturaAnterior'] ??
          lectura['ultimaLectura'] ??
          lectura['lecturaInicial'] ??
          0,
    );
  }

  double _lecturaActual(Map<String, dynamic> lectura) {
    return _num(
      lectura['lecturaActual'] ??
          lectura['lecturaNueva'] ??
          lectura['actual'] ??
          0,
    );
  }

  double _consumo(Map<String, dynamic> lectura) {
    final consumo = _num(
      lectura['consumoM3'] ??
          lectura['consumo'] ??
          lectura['consumoMes'],
    );

    if (consumo > 0) return consumo;

    final calculado = _lecturaActual(lectura) - _lecturaAnterior(lectura);

    return calculado < 0 ? 0 : calculado;
  }

  String _periodo(Map<String, dynamic> lectura) {
    final anio = int.tryParse(
          '${lectura['anio'] ?? DateTime.now().year}',
        ) ??
        DateTime.now().year;

    final mes = int.tryParse(
          '${lectura['mes'] ?? DateTime.now().month}',
        ) ??
        DateTime.now().month;

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

  String _fecha(Map<String, dynamic> lectura) {
    return _txt(
      lectura['fechaLectura'] ??
          lectura['fechaRegistro'] ??
          lectura['createdAt'] ??
          lectura['fechaEmision'],
      '-',
    );
  }

  List<Map<String, dynamic>> get lecturasFiltradas {
    final query = busqueda.trim().toLowerCase();

    if (query.isEmpty) return lecturas;

    return lecturas.where((lectura) {
      final texto = '''
      ${_codigoSuministro(lectura)}
      ${_cliente(lectura)}
      ${_direccion(lectura)}
      ${_periodo(lectura)}
      ${_fecha(lectura)}
      '''
          .toLowerCase();

      return texto.contains(query);
    }).toList();
  }

  Future<void> cargarHistorial() async {
    setState(() {
      cargando = true;
      error = '';
    });

    final combinadas = <Map<String, dynamic>>[];
    String errorServidor = '';

    try {
      final servidor = await lecturaService.listarHistorial();
      combinadas.addAll(servidor);
    } catch (e) {
      errorServidor = e.toString().replaceFirst('Exception: ', '');
    }

    if (!widget.modoAdmin) {
      try {
        final locales = await offlineService.listarHistorialLocal();
        combinadas.insertAll(0, locales);
      } catch (_) {}
    }

    combinadas.sort((a, b) {
      final fechaA = DateTime.tryParse(
            '${a['fechaRegistro'] ?? a['fechaLectura'] ?? ''}',
          ) ??
          DateTime(2000);
      final fechaB = DateTime.tryParse(
            '${b['fechaRegistro'] ?? b['fechaLectura'] ?? ''}',
          ) ??
          DateTime(2000);
      return fechaB.compareTo(fechaA);
    });

    if (!mounted) return;
    setState(() {
      lecturas = combinadas;
      error = combinadas.isEmpty ? errorServidor : '';
      cargando = false;
    });
  }

  Future<void> sincronizar() async {
    if (widget.modoAdmin) {
      await cargarHistorial();
      return;
    }
    final resultado = await sincronizacionService.sincronizarPendientes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['mensaje']?.toString() ?? 'Sincronización finalizada.'),
        backgroundColor: resultado['conectado'] == true
            ? JassColors.success
            : JassColors.warning,
      ),
    );
    await cargarHistorial();
  }

  void _volverInicio() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      widget.modoAdmin ? '/admin-dashboard' : '/lector-home',
    );
  }

  void _goAdminBottom(int index) {
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

  void _goLectorBottom(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/lector-home');
    }

    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/buscar-suministro');
    }

    if (index == 2) {
      Navigator.pushReplacementNamed(context, '/qr-scanner');
    }

    if (index == 3) return;
  }

  void _abrirMenu() {
    if (widget.modoAdmin) {
      showAdminQuickMenu(
        context: context,
        onRefresh: cargarHistorial,
      );
      return;
    }

    showLectorQuickMenu(
      context: context,
      onRefresh: sincronizar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          oscuro ? JassColors.darkBackground : JassColors.background,
      extendBody: true,
      bottomNavigationBar: widget.modoAdmin
          ? AdminBottomNav(
              currentIndex: -1,
              onTap: _goAdminBottom,
              onPlus: _abrirMenu,
            )
          : LectorBottomNav(
              currentIndex: 3,
              onTap: _goLectorBottom,
              onPlus: _abrirMenu,
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: widget.modoAdmin ? cargarHistorial : sincronizar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(oscuro),
                const SizedBox(height: 18),
                _buildSearch(oscuro),
                const SizedBox(height: 18),
                if (cargando) _buildLoading(oscuro),
                if (error.isNotEmpty && !cargando)
                  _ErrorCard(
                    error: error,
                    onRetry: cargarHistorial,
                  ),
                if (!cargando &&
                    error.isEmpty &&
                    lecturasFiltradas.isEmpty)
                  _buildEmpty(oscuro),
                if (!cargando && error.isEmpty)
                  ...lecturasFiltradas.map((lectura) {
                    return _LecturaCard(
                      codigo: _codigoSuministro(lectura),
                      cliente: _cliente(lectura),
                      direccion: _direccion(lectura),
                      periodo: _periodo(lectura),
                      fecha: _fecha(lectura),
                      lecturaAnterior: _lecturaAnterior(lectura),
                      lecturaActual: _lecturaActual(lectura),
                      consumo: _consumo(lectura),
                      total: _num(lectura['total'] ?? lectura['totalRecibo'] ?? lectura['recibo']?['total']),
                      estadoSincronizacion: _txt(
                        lectura['estadoSincronizacion'],
                        'SINCRONIZADA',
                      ),
                      oscuro: oscuro,
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool oscuro) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: oscuro ? JassColors.darkCard : JassColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  oscuro ? JassColors.darkBorder : JassColors.border,
            ),
          ),
          child: IconButton(
            onPressed: _volverInicio,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: oscuro ? Colors.white : JassColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.modoAdmin
                    ? 'Panel del administrador'
                    : 'Módulo lecturador',
                style: TextStyle(
                  color: oscuro
                      ? JassColors.darkMuted
                      : JassColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Historial de lecturas',
                style: TextStyle(
                  color: oscuro ? Colors.white : JassColors.primary,
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
            color: oscuro ? JassColors.darkCard : JassColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  oscuro ? JassColors.darkBorder : JassColors.border,
            ),
          ),
          child: IconButton(
            onPressed: sincronizar,
            icon: const Icon(
              Icons.refresh_rounded,
              color: JassColors.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch(bool oscuro) {
    return TextField(
      controller: buscarController,
      onChanged: (value) {
        setState(() {
          busqueda = value;
        });
      },
      style: TextStyle(
        color: oscuro ? Colors.white : JassColors.primary,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar por suministro, cliente o periodo...',
        hintStyle: TextStyle(
          color:
              oscuro ? JassColors.darkMuted : JassColors.muted,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: JassColors.secondary,
        ),
        filled: true,
        fillColor: oscuro ? JassColors.darkCard : JassColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color:
                oscuro ? JassColors.darkBorder : JassColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color:
                oscuro ? JassColors.darkBorder : JassColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: JassColors.secondary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(bool oscuro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: oscuro ? JassColors.darkCard : JassColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: oscuro ? JassColors.darkBorder : JassColors.border,
        ),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(
            'Cargando historial...',
            style: TextStyle(
              color:
                  oscuro ? JassColors.darkMuted : JassColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool oscuro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: oscuro ? JassColors.darkCard : JassColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: oscuro ? JassColors.darkBorder : JassColors.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            color: JassColors.secondary,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay lecturas registradas.',
            style: TextStyle(
              color: oscuro ? Colors.white : JassColors.primary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LecturaCard extends StatelessWidget {
  final String codigo;
  final String cliente;
  final String direccion;
  final String periodo;
  final String fecha;
  final double lecturaAnterior;
  final double lecturaActual;
  final double consumo;
  final double total;
  final String estadoSincronizacion;
  final bool oscuro;

  const _LecturaCard({
    required this.codigo,
    required this.cliente,
    required this.direccion,
    required this.periodo,
    required this.fecha,
    required this.lecturaAnterior,
    required this.lecturaActual,
    required this.consumo,
    required this.total,
    required this.estadoSincronizacion,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: oscuro ? JassColors.darkCard : JassColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: oscuro ? JassColors.darkBorder : JassColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE8F7FB),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: JassColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  codigo,
                  style: TextStyle(
                    color: oscuro ? Colors.white : JassColors.primary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SyncBadge(estado: estadoSincronizacion),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            cliente,
            style: TextStyle(
              color: oscuro ? Colors.white : JassColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            direccion,
            style: TextStyle(
              color:
                  oscuro ? JassColors.darkMuted : JassColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniValue(
                  label: 'Periodo',
                  value: periodo,
                  oscuro: oscuro,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniValue(
                  label: 'Fecha',
                  value: fecha,
                  oscuro: oscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniValue(
                  label: 'Anterior',
                  value: lecturaAnterior.toStringAsFixed(3),
                  oscuro: oscuro,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniValue(
                  label: 'Actual',
                  value: lecturaActual.toStringAsFixed(3),
                  oscuro: oscuro,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniValue(
                  label: 'Consumo',
                  value: '${consumo.toStringAsFixed(2)} m³',
                  oscuro: oscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: S/ ${total.toStringAsFixed(2)}',
              style: TextStyle(
                color: oscuro ? Colors.white : JassColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  final String estado;

  const _SyncBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final normalizado = estado.toUpperCase();
    final pendiente = normalizado == 'PENDIENTE' || normalizado == 'SINCRONIZANDO';
    final error = normalizado == 'ERROR';
    final color = error
        ? JassColors.danger
        : pendiente
            ? JassColors.warning
            : JassColors.success;
    final texto = error
        ? 'ERROR'
        : pendiente
            ? 'PENDIENTE'
            : 'SINCRONIZADA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  final String label;
  final String value;
  final bool oscuro;

  const _MiniValue({
    required this.label,
    required this.value,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: oscuro
            ? const Color(0xFF162432)
            : const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: oscuro ? JassColors.darkBorder : JassColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  oscuro ? JassColors.darkMuted : JassColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: oscuro ? Colors.white : JassColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorCard({
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
        border: Border.all(
          color: const Color(0xFFFFD1D1),
        ),
      ),
      child: Column(
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: JassColors.danger,
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
