import 'package:flutter/material.dart';

import '../../core/services/recibo_service.dart';
import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import '../../shared/widgets/cliente_bottom_nav.dart';

class DetalleSuministroClientePage extends StatefulWidget {
  const DetalleSuministroClientePage({super.key});

  @override
  State<DetalleSuministroClientePage> createState() =>
      _DetalleSuministroClientePageState();
}

class _DetalleSuministroClientePageState
    extends State<DetalleSuministroClientePage> {
  final ReciboService reciboService = ReciboService();

  Map<String, dynamic> suministro = {};
  List<Map<String, dynamic>> recibos = [];

  bool inicializado = false;
  bool cargando = false;
  String error = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (inicializado) return;
    inicializado = true;

    final argumentos = ModalRoute.of(context)?.settings.arguments;

    if (argumentos is Map<String, dynamic>) {
      suministro = argumentos;
    } else if (argumentos is Map) {
      suministro = Map<String, dynamic>.from(argumentos);
    }

    cargarRecibos();
  }

  String _texto(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final texto = value.toString().trim();

    if (texto.isEmpty || texto == 'null') return fallback;

    return texto;
  }

  double _numero(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  String _normalizarCodigo(dynamic value) {
    return _texto(value, '').trim().toUpperCase();
  }

  String get codigoSuministro {
    return _texto(
      suministro['codigoSuministro'] ??
          suministro['suministroCodigo'] ??
          suministro['codigo'] ??
          suministro['numeroSuministro'],
      'SIN-CÓDIGO',
    );
  }

  String get aliasSuministro {
    return _texto(
      suministro['aliasSuministro'] ?? suministro['alias'],
      'Sin alias registrado',
    );
  }

  String get sector {
    return _texto(
      suministro['nombreSector'] ??
          suministro['sectorNombre'] ??
          suministro['sector'],
      'Sector no registrado',
    );
  }

  String get direccion {
    return _texto(
      suministro['direccionSuministro'] ??
          suministro['direccion'] ??
          suministro['direccionCliente'],
      'Dirección no registrada',
    );
  }

  String get referencia {
    return _texto(
      suministro['referencia'] ??
          suministro['referenciaSuministro'],
      'Sin referencia registrada',
    );
  }

  double get lecturaInicial {
    return _numero(
      suministro['lecturaInicial'] ??
          suministro['lecturaInicialM3'] ??
          suministro['lectura'],
    );
  }

  bool get activo {
    final value = suministro['estado'];

    if (value is bool) return value;

    final texto = value.toString().toUpperCase();

    return texto == 'TRUE' || texto == 'ACTIVO';
  }

  int _idRecibo(Map<String, dynamic> recibo) {
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
          'REC-${_idRecibo(recibo)}',
    );
  }

  String _codigoSuministroRecibo(Map<String, dynamic> recibo) {
    return _normalizarCodigo(
      recibo['codigoSuministro'] ??
          recibo['suministroCodigo'] ??
          recibo['codigoSuministroRecibo'] ??
          recibo['numeroSuministro'] ??
          recibo['suministro'],
    );
  }

  String _estadoRecibo(Map<String, dynamic> recibo) {
    return _texto(
      recibo['estadoRecibo'] ??
          recibo['estado'] ??
          recibo['situacion'],
      'PENDIENTE',
    ).toUpperCase();
  }

  double _totalRecibo(Map<String, dynamic> recibo) {
    return _numero(
      recibo['total'] ??
          recibo['montoTotal'] ??
          recibo['importeTotal'] ??
          recibo['totalPagar'],
    );
  }

  double _consumoRecibo(Map<String, dynamic> recibo) {
    return _numero(
      recibo['consumoM3'] ??
          recibo['consumo'] ??
          recibo['consumoMes'],
    );
  }

  double _lecturaActualRecibo(Map<String, dynamic> recibo) {
    return _numero(
      recibo['lecturaActual'] ??
          recibo['lecturaActualM3'] ??
          recibo['lecturaFinal'],
    );
  }

  String _periodoRecibo(Map<String, dynamic> recibo) {
    final mes = int.tryParse('${recibo['mes'] ?? 0}') ?? 0;
    final anio = int.tryParse('${recibo['anio'] ?? 0}') ?? 0;

    if (mes >= 1 && mes <= 12 && anio > 0) {
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

      return '${meses[mes - 1]} $anio';
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

  Future<void> cargarRecibos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final todosLosRecibos = await reciboService.listarMisRecibos();
      final codigoActual = _normalizarCodigo(codigoSuministro);

      final recibosFiltrados = todosLosRecibos.where((recibo) {
        return _codigoSuministroRecibo(recibo) == codigoActual;
      }).toList();

      recibosFiltrados.sort((a, b) {
        return _periodoNumero(b).compareTo(_periodoNumero(a));
      });

      if (!mounted) return;

      setState(() {
        recibos = recibosFiltrados;
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

  Map<String, dynamic>? get ultimoRecibo {
    if (recibos.isEmpty) return null;

    return recibos.first;
  }

  Map<String, dynamic>? get reciboPendiente {
    try {
      return recibos.firstWhere((recibo) {
        final estado = _estadoRecibo(recibo);

        return estado == 'PENDIENTE' || estado == 'VENCIDO';
      });
    } catch (_) {
      return null;
    }
  }

  double get deudaPendiente {
    return recibos.where((recibo) {
      final estado = _estadoRecibo(recibo);

      return estado == 'PENDIENTE' || estado == 'VENCIDO';
    }).fold(0, (suma, recibo) {
      return suma + _totalRecibo(recibo);
    });
  }

  double get ultimaLectura {
    if (ultimoRecibo == null) return lecturaInicial;

    final lectura = _lecturaActualRecibo(ultimoRecibo!);

    return lectura > 0 ? lectura : lecturaInicial;
  }

  double get ultimoConsumo {
    if (ultimoRecibo == null) return 0;

    return _consumoRecibo(ultimoRecibo!);
  }

  void _irHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _irSuministros() {
    Navigator.pushReplacementNamed(context, '/mis-suministros');
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

  void _verRecibo(Map<String, dynamic> recibo) {
    Navigator.pushNamed(
      context,
      '/recibo-detalle',
      arguments: recibo,
    );
  }

  void _pagarRecibo() {
    final recibo = reciboPendiente;

    if (recibo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Este suministro no tiene recibos pendientes.'),
          backgroundColor: JassColors.success,
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

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _irSuministros();
    }
  }

  void _goBottomCliente(int index) {
    if (index == 0) {
      _irHome();
    }

    if (index == 1) {
      _irRecibos();
    }

    if (index == 2) {
      _pagarRecibo();
    }

    if (index == 3) {
      _irPerfil();
    }
  }

  void _abrirMenuCliente() {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

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
                      color:
                          oscuro ? JassColors.darkCard : JassColors.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: oscuro
                            ? JassColors.darkBorder
                            : JassColors.border,
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
                          icon: Icons.water_drop_rounded,
                          label: 'Suministros',
                          onTap: () {
                            Navigator.pop(context);
                            _irSuministros();
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
                            _pagarRecibo();
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
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          oscuro ? JassColors.darkBackground : JassColors.background,
      extendBody: true,
      bottomNavigationBar: ClienteBottomNav(
        currentIndex: -1,
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
                _buildHeader(oscuro),
                SizedBox(height: 18),
                _buildHero(),
                SizedBox(height: 18),
                _buildResumen(oscuro),
                SizedBox(height: 18),
                _buildInformacion(oscuro),
                SizedBox(height: 18),
                if (cargando) _buildLoading(oscuro),
                if (error.isNotEmpty && !cargando) _buildError(),
                if (!cargando && error.isEmpty) _buildRecibos(oscuro),
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
        _HeaderButton(
          icon: Icons.arrow_back_rounded,
          onPressed: _volver,
          oscuro: oscuro,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Portal cliente',
                style: TextStyle(
                  color:
                      oscuro ? JassColors.darkMuted : JassColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Detalle del suministro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      oscuro ? Colors.white : JassColors.primary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _HeaderButton(
          icon: Icons.refresh_rounded,
          onPressed: cargarRecibos,
          oscuro: oscuro,
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JassColors.primary,
            JassColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2607384A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      codigoSuministro,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      aliasSuministro,
                      style: TextStyle(
                        color: Color(0xFFE7F8FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                    color: activo
                        ? JassColors.success
                        : JassColors.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _HeroInfo(
                  label: 'Sector',
                  value: sector,
                ),
                _HeroInfo(
                  label: 'Dirección',
                  value: direccion,
                ),
                _HeroInfo(
                  label: 'Referencia',
                  value: referencia,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen(bool oscuro) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _ResumenCard(
          icon: Icons.speed_rounded,
          label: 'Última lectura',
          value: '${ultimaLectura.toStringAsFixed(3)} m³',
          oscuro: oscuro,
        ),
        _ResumenCard(
          icon: Icons.bar_chart_rounded,
          label: 'Último consumo',
          value: '${ultimoConsumo.toStringAsFixed(2)} m³',
          oscuro: oscuro,
        ),
        _ResumenCard(
          icon: Icons.receipt_long_rounded,
          label: 'Recibos',
          value: '${recibos.length}',
          oscuro: oscuro,
        ),
        _ResumenCard(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Deuda',
          value: 'S/ ${deudaPendiente.toStringAsFixed(2)}',
          oscuro: oscuro,
        ),
      ],
    );
  }

  Widget _buildInformacion(bool oscuro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: oscuro ? JassColors.darkCard : JassColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color:
              oscuro ? JassColors.darkBorder : JassColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del suministro',
            style: TextStyle(
              color: oscuro ? Colors.white : JassColors.primary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          _DetalleInfo(
            icon: Icons.numbers_rounded,
            label: 'Código',
            value: codigoSuministro,
            oscuro: oscuro,
          ),
          _DetalleInfo(
            icon: Icons.bookmark_rounded,
            label: 'Alias',
            value: aliasSuministro,
            oscuro: oscuro,
          ),
          _DetalleInfo(
            icon: Icons.map_rounded,
            label: 'Sector',
            value: sector,
            oscuro: oscuro,
          ),
          _DetalleInfo(
            icon: Icons.place_rounded,
            label: 'Dirección',
            value: direccion,
            oscuro: oscuro,
          ),
          _DetalleInfo(
            icon: Icons.info_outline_rounded,
            label: 'Referencia',
            value: referencia,
            oscuro: oscuro,
          ),
          _DetalleInfo(
            icon: Icons.speed_outlined,
            label: 'Lectura inicial',
            value: '${lecturaInicial.toStringAsFixed(3)} m³',
            oscuro: oscuro,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(bool oscuro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: oscuro ? JassColors.darkCard : JassColors.card,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Cargando recibos del suministro...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: JassColors.muted,
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
            color: JassColors.danger,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: JassColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14),
          ElevatedButton(
            onPressed: cargarRecibos,
            style: ElevatedButton.styleFrom(
              backgroundColor: JassColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecibos(bool oscuro) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: oscuro ? JassColors.darkCard : JassColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color:
              oscuro ? JassColors.darkBorder : JassColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: JassColors.secondary,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Últimos recibos',
                  style: TextStyle(
                    color: oscuro ? Colors.white : JassColors.primary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: _irRecibos,
                child: Text('Ver todos'),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (recibos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Este suministro no tiene recibos registrados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: oscuro
                        ? JassColors.darkMuted
                        : JassColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              itemCount: recibos.length > 3 ? 3 : recibos.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, _) => SizedBox(height: 10),
              itemBuilder: (context, index) {
                final recibo = recibos[index];

                return _ReciboSuministroCard(
                  codigo: _codigoRecibo(recibo),
                  periodo: _periodoRecibo(recibo),
                  consumo: _consumoRecibo(recibo),
                  total: _totalRecibo(recibo),
                  estado: _estadoRecibo(recibo),
                  oscuro: oscuro,
                  onTap: () => _verRecibo(recibo),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool oscuro;

  const _HeaderButton({
    required this.icon,
    required this.onPressed,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: oscuro ? JassColors.darkCard : JassColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              oscuro ? JassColors.darkBorder : JassColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: oscuro ? Colors.white : JassColors.primary,
        ),
      ),
    );
  }
}

class _HeroInfo extends StatelessWidget {
  final String label;
  final String value;

  const _HeroInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
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

class _ResumenCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool oscuro;

  const _ResumenCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: oscuro ? JassColors.darkCard : JassColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              oscuro ? JassColors.darkBorder : JassColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.water_drop_outlined,
            color: JassColors.secondary,
            size: 27,
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: oscuro ? Colors.white : JassColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  oscuro ? JassColors.darkMuted : JassColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalleInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool oscuro;

  const _DetalleInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.oscuro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: oscuro
            ? const Color(0xFF162432)
            : context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              oscuro ? JassColors.darkBorder : JassColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: JassColors.secondary,
            size: 21,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                    oscuro ? JassColors.darkMuted : JassColors.muted,
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
                color: oscuro ? Colors.white : JassColors.primary,
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

class _ReciboSuministroCard extends StatelessWidget {
  final String codigo;
  final String periodo;
  final double consumo;
  final double total;
  final String estado;
  final bool oscuro;
  final VoidCallback onTap;

  const _ReciboSuministroCard({
    required this.codigo,
    required this.periodo,
    required this.consumo,
    required this.total,
    required this.estado,
    required this.oscuro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: oscuro
              ? const Color(0xFF162432)
              : context.jassSurfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                oscuro ? JassColors.darkBorder : JassColors.border,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.jassSelectedSurface,
              child: Icon(
                Icons.receipt_long_rounded,
                color: JassColors.secondary,
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    codigo,
                    style: TextStyle(
                      color:
                          oscuro ? Colors.white : JassColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$periodo · ${consumo.toStringAsFixed(2)} m³',
                    style: TextStyle(
                      color: oscuro
                          ? JassColors.darkMuted
                          : JassColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'S/ ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        oscuro ? Colors.white : JassColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                _EstadoReciboBadge(estado: estado),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoReciboBadge extends StatelessWidget {
  final String estado;

  const _EstadoReciboBadge({
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final upper = estado.toUpperCase();

    Color fondo;
    Color texto;

    if (upper == 'PAGADO') {
      fondo = const Color(0xFFEAF8EF);
      texto = JassColors.success;
    } else if (upper == 'VENCIDO') {
      fondo = const Color(0xFFFFECEC);
      texto = JassColors.danger;
    } else {
      fondo = const Color(0xFFFFF3DF);
      texto = JassColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        upper,
        style: TextStyle(
          color: texto,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
