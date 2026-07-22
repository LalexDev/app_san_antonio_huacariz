// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations
import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/recibo_service.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminRecibosPage extends StatefulWidget {
  const AdminRecibosPage({super.key});

  @override
  State<AdminRecibosPage> createState() => _AdminRecibosPageState();
}

class _AdminRecibosPageState extends State<AdminRecibosPage> {
  final Color secondary = JassColors.secondary;
  final ReciboService reciboService = ReciboService();

  List<Map<String, dynamic>> recibos = [];
  bool cargando = false;
  String error = '';
  String busqueda = '';
  String filtroEstado = 'TODOS';

  @override
  void initState() {
    super.initState();
    cargarRecibos();
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

  int _idRecibo(Map<String, dynamic> recibo) {
    final value = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String _codigoRecibo(Map<String, dynamic> recibo) {
    return _txt(
      recibo['codigoRecibo'] ?? recibo['numeroRecibo'] ?? recibo['codigo'],
      'REC-${_idRecibo(recibo)}',
    );
  }

  String _codigoSuministro(Map<String, dynamic> recibo) {
    return _txt(
      recibo['codigoSuministro'] ??
          recibo['suministroCodigo'] ??
          recibo['suministro'],
    );
  }

  String _cliente(Map<String, dynamic> recibo) {
    return _txt(
      recibo['cliente'] ??
          recibo['nombreCliente'] ??
          recibo['titular'] ??
          recibo['nombres'] ??
          recibo['usuario'],
      'Usuario del servicio',
    );
  }

  String _direccion(Map<String, dynamic> recibo) {
    return _txt(
      recibo['direccionSuministro'] ??
          recibo['direccion'] ??
          recibo['direccionCliente'],
      'Dirección no registrada',
    );
  }

  String _estado(Map<String, dynamic> recibo) {
    return _txt(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    ).toUpperCase();
  }

  double _consumo(Map<String, dynamic> recibo) {
    return _num(
      recibo['consumoM3'] ?? recibo['consumo'] ?? recibo['consumoMes'] ?? 0,
    );
  }

  double _total(Map<String, dynamic> recibo) {
    return _num(
      recibo['total'] ?? recibo['montoTotal'] ?? recibo['importeTotal'] ?? 0,
    );
  }

  String _vencimiento(Map<String, dynamic> recibo) {
    return _txt(
      recibo['fechaVencimiento'] ?? recibo['vencimiento'],
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

    return _txt(
      recibo['periodo'] ?? recibo['mesFacturado'],
      'Periodo no registrado',
    );
  }

  bool _puedeMarcarPagado(Map<String, dynamic> recibo) {
    final estado = _estado(recibo);
    return estado == 'PENDIENTE' || estado == 'VENCIDO';
  }

  List<Map<String, dynamic>> get recibosFiltrados {
    final query = busqueda.trim().toLowerCase();

    return recibos.where((recibo) {
      final estado = _estado(recibo);

      final cumpleEstado =
          filtroEstado == 'TODOS' ? true : estado == filtroEstado;

      final texto = '''
      ${_codigoRecibo(recibo)}
      ${_codigoSuministro(recibo)}
      ${_cliente(recibo)}
      ${_direccion(recibo)}
      ${_periodo(recibo)}
      ${_estado(recibo)}
      '''
          .toLowerCase();

      final cumpleBusqueda = query.isEmpty ? true : texto.contains(query);

      return cumpleEstado && cumpleBusqueda;
    }).toList();
  }

  int get totalRecibos => recibos.length;

  int get pendientes {
    return recibos.where((r) => _estado(r) == 'PENDIENTE').length;
  }

  int get pagados {
    return recibos.where((r) => _estado(r) == 'PAGADO').length;
  }

  int get vencidos {
    return recibos.where((r) => _estado(r) == 'VENCIDO').length;
  }

  double get deudaTotal {
    return recibos.where((r) {
      final estado = _estado(r);
      return estado == 'PENDIENTE' || estado == 'VENCIDO';
    }).fold(0.0, (sum, recibo) => sum + _total(recibo));
  }

  Future<void> cargarRecibos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await reciboService.listarRecibosAdmin();

      if (!mounted) return;

      setState(() {
        recibos = data;
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

  Future<void> _buscarPorSuministro(String codigo) async {
    final texto = codigo.trim();

    if (texto.isEmpty) {
      await cargarRecibos();
      return;
    }

    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await reciboService.buscarPorSuministroAdmin(texto);

      if (!mounted) return;

      setState(() {
        recibos = data;
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

  Future<void> _marcarPagado(Map<String, dynamic> recibo) async {
    final idRecibo = _idRecibo(recibo);

    if (idRecibo <= 0) {
      _mensaje('No se encontró el ID del recibo.', true);
      return;
    }

    final codigoOperacionController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: context.jassSurface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (contextSheet) {
        bool guardando = false;
        String metodoPago = 'YAPE';

        return StatefulBuilder(
          builder: (contextSheet, setModalState) {
            Future<void> confirmar() async {
              final codigoOperacion =
                  codigoOperacionController.text.trim().isEmpty
                      ? 'ADMIN-${DateTime.now().millisecondsSinceEpoch}'
                      : codigoOperacionController.text.trim();

              setModalState(() {
                guardando = true;
              });

              try {
                await reciboService.pagarReciboAdmin(
                  idRecibo: idRecibo,
                  metodoPago: metodoPago,
                  codigoOperacion: codigoOperacion,
                );

                if (!mounted) return;

                Navigator.pop(contextSheet);

                _mensaje('Recibo marcado como pagado.', false);

                await cargarRecibos();
              } catch (e) {
                setModalState(() {
                  guardando = false;
                });

                _mensaje(
                  e.toString().replaceFirst('Exception: ', ''),
                  true,
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 22,
                bottom: MediaQuery.of(contextSheet).viewInsets.bottom + 22,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registrar pago presencial',
                      style: TextStyle(
                        color: context.jassTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_codigoRecibo(recibo)} · S/ ${_total(recibo).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: context.jassTextMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: metodoPago,
                      decoration: InputDecoration(
                        labelText: 'Método de pago',
                        filled: true,
                        fillColor: context.jassSurfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'YAPE',
                          child: Text('Yape'),
                        ),
                        DropdownMenuItem(
                          value: 'PLIN',
                          child: Text('Plin'),
                        ),
                        DropdownMenuItem(
                          value: 'TRANSFERENCIA',
                          child: Text('Transferencia bancaria'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          metodoPago = value;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: codigoOperacionController,
                      decoration: InputDecoration(
                        labelText: 'Código de operación',
                        hintText: 'Ejemplo: OP-123456',
                        filled: true,
                        fillColor: context.jassSurfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: guardando ? null : confirmar,
                        icon: guardando
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.check_circle_outline),
                        label: Text(
                          guardando ? 'Guardando...' : 'Confirmar pago',
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    codigoOperacionController.dispose();
  }

  void _mensaje(String mensaje, bool esError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            esError ? JassColors.danger : JassColors.success,
      ),
    );
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

    if (index == 3) return;
  }

  void _abrirMenuAdmin() {
    showAdminQuickMenu(
      context: context,
      onRefresh: cargarRecibos,
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 3,
        onTap: _go,
        onPlus: _abrirMenuAdmin,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarRecibos,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 16),
                _buildStats(),
                SizedBox(height: 16),
                _buildSearch(),
                SizedBox(height: 14),
                _buildFilters(),
                SizedBox(height: 16),
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
                    onRetry: cargarRecibos,
                  ),
                if (!cargando && error.isEmpty && recibosFiltrados.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('No hay recibos para mostrar.'),
                    ),
                  ),
                if (!cargando && error.isEmpty)
                  ...recibosFiltrados.map((recibo) {
                    return _ReciboCard(
                      codigoRecibo: _codigoRecibo(recibo),
                      codigoSuministro: _codigoSuministro(recibo),
                      cliente: _cliente(recibo),
                      direccion: _direccion(recibo),
                      periodo: _periodo(recibo),
                      consumo: _consumo(recibo),
                      total: _total(recibo),
                      vencimiento: _vencimiento(recibo),
                      estado: _estado(recibo),
                      puedeMarcarPagado: _puedeMarcarPagado(recibo),
                      onPagar: () => _marcarPagado(recibo),
                    );
                  }),
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
                'Facturación mensual',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Recibos',
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
          onPressed: cargarRecibos,
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
                label: 'Total',
                value: '$totalRecibos',
                icon: Icons.receipt_long_rounded,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pendientes',
                value: '$pendientes',
                icon: Icons.pending_actions_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pagados',
                value: '$pagados',
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Vencidos',
                value: '$vencidos',
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _StatCard(
            label: 'Deuda pendiente',
            value: 'S/ ${deudaTotal.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (value) {
        setState(() {
          busqueda = value;
        });
      },
      onSubmitted: _buscarPorSuministro,
      decoration: InputDecoration(
        hintText: 'Buscar por recibo, cliente o suministro...',
        prefixIcon: Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: () => _buscarPorSuministro(busqueda),
          icon: Icon(Icons.manage_search_rounded),
        ),
        filled: true,
        fillColor: context.jassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filtros = [
      {'value': 'TODOS', 'label': 'Todos'},
      {'value': 'PENDIENTE', 'label': 'Pendientes'},
      {'value': 'PAGADO', 'label': 'Pagados'},
      {'value': 'VENCIDO', 'label': 'Vencidos'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((item) {
          final selected = filtroEstado == item['value'];

          return Padding(
            padding: EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: selected,
              selectedColor: secondary,
              backgroundColor: context.jassSurface,
              side: BorderSide(
                color: context.jassBorder,
              ),
              label: Text(
                item['label']!,
                style: TextStyle(
                  color: selected ? Colors.white : context.jassTextPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  filtroEstado = item['value']!;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  _StatCard({
    required this.label,
    required this.value,
    required this.icon,
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
            size: 28,
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReciboCard extends StatelessWidget {
  final String codigoRecibo;
  final String codigoSuministro;
  final String cliente;
  final String direccion;
  final String periodo;
  final double consumo;
  final double total;
  final String vencimiento;
  final String estado;
  final bool puedeMarcarPagado;
  final VoidCallback onPagar;

  _ReciboCard({
    required this.codigoRecibo,
    required this.codigoSuministro,
    required this.cliente,
    required this.direccion,
    required this.periodo,
    required this.consumo,
    required this.total,
    required this.vencimiento,
    required this.estado,
    required this.puedeMarcarPagado,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    final Color secondary = JassColors.secondary;

    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(16),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  codigoRecibo,
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _EstadoBadge(estado: estado),
            ],
          ),
          SizedBox(height: 8),
          Text(
            cliente,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Suministro: $codigoSuministro',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            direccion,
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'Periodo',
                  value: periodo,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniInfo(
                  label: 'Consumo',
                  value: '${consumo.toStringAsFixed(2)} m³',
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  label: 'Total',
                  value: 'S/ ${total.toStringAsFixed(2)}',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniInfo(
                  label: 'Vence',
                  value: vencimiento,
                ),
              ),
            ],
          ),
          if (puedeMarcarPagado) ...[
            SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: onPagar,
                icon: Icon(Icons.payments_rounded),
                label: Text(
                  'Registrar pago presencial',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  _MiniInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.jassTextMuted,
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
              color: context.jassTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;

  _EstadoBadge({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final upper = estado.toUpperCase();

    Color bg;
    Color text;

    if (upper == 'PAGADO') {
      bg = Color(0xFFEAF8EF);
      text = JassColors.success;
    } else if (upper == 'VENCIDO') {
      bg = Color(0xFFFFECEC);
      text = JassColors.danger;
    } else {
      bg = Color(0xFFFFF3DF);
      text = JassColors.warning;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        upper,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
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
