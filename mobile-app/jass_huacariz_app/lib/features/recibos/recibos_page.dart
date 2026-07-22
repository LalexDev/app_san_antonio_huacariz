import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/cliente_portal_service.dart';
import '../../core/services/recibo_service.dart';
import '../../shared/widgets/cliente_bottom_nav.dart';

class RecibosPage extends StatefulWidget {
  const RecibosPage({super.key});

  @override
  State<RecibosPage> createState() => _RecibosPageState();
}

class _RecibosPageState extends State<RecibosPage> {
  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;
  Color get background => context.jassBackground;
  Color get muted => context.jassTextMuted;

  final ReciboService reciboService = ReciboService();
  final ClientePortalService clientePortalService = ClientePortalService();

  List<Map<String, dynamic>> recibos = [];
  List<Map<String, dynamic>> suministros = [];

  bool cargando = false;
  String error = '';
  String filtro = 'TODOS';

  @override
  void initState() {
    super.initState();
    cargarRecibos();
  }

  String _texto(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  String _normalizarCodigo(String value) {
    return value.trim().toUpperCase();
  }

  String _codigoSuministroDesdeSuministro(Map<String, dynamic> suministro) {
    return _normalizarCodigo(
      _texto(
        suministro['codigoSuministro'] ??
            suministro['suministroCodigo'] ??
            suministro['codigo'] ??
            suministro['numeroSuministro'],
        '',
      ),
    );
  }

  String _codigoSuministro(Map<String, dynamic> recibo) {
    return _normalizarCodigo(
      _texto(
        recibo['codigoSuministro'] ??
            recibo['suministroCodigo'] ??
            recibo['codigoSuministroRecibo'] ??
            recibo['numeroSuministro'] ??
            recibo['suministro'],
        'SIN-SUMINISTRO',
      ),
    );
  }

  Future<void> cargarRecibos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final recibosData = await reciboService.listarMisRecibos();
      final suministrosData = await clientePortalService.listarMisSuministros();

      final codigosSuministroCliente = suministrosData
          .map(_codigoSuministroDesdeSuministro)
          .where((codigo) => codigo.isNotEmpty)
          .toSet();

      final recibosValidados = recibosData.where((recibo) {
        final codigoReciboSuministro = _codigoSuministro(recibo);

        if (codigoReciboSuministro.isEmpty ||
            codigoReciboSuministro == 'SIN-SUMINISTRO') {
          return false;
        }

        return codigosSuministroCliente.contains(codigoReciboSuministro);
      }).toList();

      recibosValidados.sort((a, b) {
        final anioA = int.tryParse('${a['anio'] ?? 0}') ?? 0;
        final anioB = int.tryParse('${b['anio'] ?? 0}') ?? 0;
        final mesA = int.tryParse('${a['mes'] ?? 0}') ?? 0;
        final mesB = int.tryParse('${b['mes'] ?? 0}') ?? 0;

        final periodoA = anioA * 100 + mesA;
        final periodoB = anioB * 100 + mesB;

        return periodoB.compareTo(periodoA);
      });

      if (!mounted) return;

      setState(() {
        suministros = suministrosData;
        recibos = recibosValidados;
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

  List<Map<String, dynamic>> get recibosFiltrados {
    if (filtro == 'TODOS') return recibos;

    return recibos.where((recibo) {
      final estado = _estado(recibo).toUpperCase();
      return estado == filtro;
    }).toList();
  }

  Map<String, dynamic>? get reciboPendiente {
    try {
      return recibos.firstWhere((recibo) => _puedePagar(recibo));
    } catch (_) {
      return null;
    }
  }

  int get totalRecibos => recibos.length;

  int get pendientes {
    return recibos.where((recibo) {
      return _estado(recibo).toUpperCase() == 'PENDIENTE';
    }).length;
  }

  int get vencidos {
    return recibos.where((recibo) {
      return _estado(recibo).toUpperCase() == 'VENCIDO';
    }).length;
  }

  int get pagados {
    return recibos.where((recibo) {
      return _estado(recibo).toUpperCase() == 'PAGADO';
    }).length;
  }

  double get deudaPendiente {
    return recibos.where((recibo) {
      final estado = _estado(recibo).toUpperCase();
      return estado == 'PENDIENTE' || estado == 'VENCIDO';
    }).fold(0.0, (sum, recibo) {
      return sum + _total(recibo);
    });
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
      final nombreMes = meses[(mesNumero - 1).clamp(0, 11)];

      return '$nombreMes $anio';
    }

    return _texto(
      recibo['periodo'] ?? recibo['mesFacturado'],
      'Periodo no registrado',
    );
  }

  double _numero(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  double _consumo(Map<String, dynamic> recibo) {
    return _numero(
      recibo['consumoM3'] ?? recibo['consumo'] ?? recibo['consumoMes'] ?? 0,
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

  String _estado(Map<String, dynamic> recibo) {
    return _texto(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    ).toUpperCase();
  }

  String _vencimiento(Map<String, dynamic> recibo) {
    return _texto(
      recibo['fechaVencimiento'] ?? recibo['vencimiento'],
      '-',
    );
  }

  bool _puedePagar(Map<String, dynamic> recibo) {
    final estado = _estado(recibo);
    return estado == 'PENDIENTE' || estado == 'VENCIDO';
  }

  void _verDetalle(Map<String, dynamic> recibo) {
    Navigator.pushNamed(
      context,
      '/recibo-detalle',
      arguments: recibo,
    );
  }

  void _pagar(Map<String, dynamic> recibo) {
    Navigator.pushNamed(
      context,
      '/pago-cip',
      arguments: recibo,
    );
  }

  void _irHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _irPerfil() {
    Navigator.pushReplacementNamed(context, '/perfil');
  }

  void _irCambiarPassword() {
    Navigator.pushNamed(context, '/cambiar-password');
  }

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _irHome();
    }
  }

  void _pagarPendiente() {
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

    _pagar(recibo);
  }

  // Barra inferior cliente:
  // 0 = Inicio, 1 = Recibos, 2 = Pagar, 3 = Perfil.
  void _goBottomCliente(int index) {
    if (index == 0) {
      _irHome();
    }

    if (index == 1) return;

    if (index == 2) {
      _pagarPendiente();
    }

    if (index == 3) {
      _irPerfil();
    }
  }

  // Menú blanco del botón "+".
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
                          icon: Icons.payments_rounded,
                          label: 'Pagar',
                          onTap: () {
                            Navigator.pop(context);
                            _pagarPendiente();
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
                            cargarRecibos();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.arrow_back_rounded,
                          label: 'Volver',
                          onTap: () {
                            Navigator.pop(context);
                            _volver();
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
        currentIndex: 1,
        onTap: _goBottomCliente,
        onPlus: _abrirMenuCliente,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarRecibos,
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
                _buildStats(),
                SizedBox(height: 18),
                _buildFilters(),
                SizedBox(height: 18),
                if (cargando) _buildLoading(),
                if (error.isNotEmpty && !cargando) _buildError(),
                if (!cargando && error.isEmpty) _buildRecibosList(),
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
                'Mis recibos',
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
            onPressed: cargarRecibos,
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
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consulta tus recibos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Suministros asociados: ${suministros.length}',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
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
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        _StatCard(
          icon: Icons.receipt_long_rounded,
          label: 'Total recibos',
          value: '$totalRecibos',
          color: secondary,
        ),
        _StatCard(
          icon: Icons.pending_actions_rounded,
          label: 'Pendientes',
          value: '$pendientes',
          color: const Color(0xFFC77700),
        ),
        _StatCard(
          icon: Icons.warning_amber_rounded,
          label: 'Vencidos',
          value: '$vencidos',
          color: const Color(0xFFD93025),
        ),
        _StatCard(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Deuda',
          value: 'S/ ${deudaPendiente.toStringAsFixed(2)}',
          color: const Color(0xFF1DA1C2),
        ),
      ],
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
          final selected = filtro == item['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: selected,
              selectedColor: secondary,
              backgroundColor: context.jassSurface,
              side: BorderSide(color: context.jassBorder),
              label: Text(
                item['label']!,
                style: TextStyle(
                  color: selected ? Colors.white : muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onSelected: (_) {
                setState(() {
                  filtro = item['value']!;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Cargando recibos...',
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
            size: 40,
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
            onPressed: cargarRecibos,
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

  Widget _buildRecibosList() {
    if (recibosFiltrados.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: context.jassSurface,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: secondary,
              size: 54,
            ),
            SizedBox(height: 12),
            Text(
              'No hay recibos para mostrar',
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
      itemCount: recibosFiltrados.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => SizedBox(height: 14),
      itemBuilder: (context, index) {
        final recibo = recibosFiltrados[index];

        return _ReciboCard(
          codigoRecibo: _codigoRecibo(recibo),
          codigoSuministro: _codigoSuministro(recibo),
          direccion: _direccion(recibo),
          periodo: _periodo(recibo),
          consumo: _consumo(recibo),
          total: _total(recibo),
          vencimiento: _vencimiento(recibo),
          estado: _estado(recibo),
          puedePagar: _puedePagar(recibo),
          onVerDetalle: () => _verDetalle(recibo),
          onPagar: () => _pagar(recibo),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    final Color muted = context.jassTextMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
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
  final String direccion;
  final String periodo;
  final double consumo;
  final double total;
  final String vencimiento;
  final String estado;
  final bool puedePagar;
  final VoidCallback onVerDetalle;
  final VoidCallback onPagar;

  const _ReciboCard({
    required this.codigoRecibo,
    required this.codigoSuministro,
    required this.direccion,
    required this.periodo,
    required this.consumo,
    required this.total,
    required this.vencimiento,
    required this.estado,
    required this.puedePagar,
    required this.onVerDetalle,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    const Color secondary = JassColors.secondary;
    final Color muted = context.jassTextMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.jassBorder),
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
              Expanded(
                child: Text(
                  codigoRecibo,
                  style: TextStyle(
                    color: primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _EstadoBadge(estado: estado),
            ],
          ),
          SizedBox(height: 8),
          _InfoLine(icon: Icons.water_drop_rounded, text: codigoSuministro),
          _InfoLine(icon: Icons.place_rounded, text: direccion),
          _InfoLine(icon: Icons.calendar_month_rounded, text: periodo),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniBox(
                  label: 'Consumo',
                  value: '${consumo.toStringAsFixed(2)} m³',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniBox(
                  label: 'Total',
                  value: 'S/ ${total.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _InfoLine(
            icon: Icons.event_busy_rounded,
            text: 'Vence: $vencimiento',
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onVerDetalle,
                  icon: Icon(Icons.visibility_outlined, size: 18),
                  label: Text(
                    'Ver recibo',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    backgroundColor: context.jassSelectedSurface,
                    side: BorderSide(color: context.jassBorder),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              if (puedePagar) ...[
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPagar,
                    icon: Icon(Icons.payment_rounded, size: 18),
                    label: Text(
                      'Pagar',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
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
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 17, color: muted),
          SizedBox(width: 7),
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
          SizedBox(height: 5),
          Text(
            value,
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

class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final estadoUpper = estado.toUpperCase();

    Color bg;
    Color text;

    if (estadoUpper == 'PAGADO') {
      bg = const Color(0xFFEAF8EF);
      text = const Color(0xFF1F8F4D);
    } else if (estadoUpper == 'VENCIDO') {
      bg = const Color(0xFFFFECEC);
      text = const Color(0xFFD93025);
    } else {
      bg = const Color(0xFFFFF3DF);
      text = const Color(0xFFC77700);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        estadoUpper,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
