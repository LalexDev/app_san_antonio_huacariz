import 'package:flutter/material.dart';

import '../../core/services/tarifa_service.dart';
import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminTarifasPage extends StatefulWidget {
  const AdminTarifasPage({super.key});

  @override
  State<AdminTarifasPage> createState() => _AdminTarifasPageState();
}

class _AdminTarifasPageState extends State<AdminTarifasPage> {
  final TarifaService tarifaService = TarifaService();

  final cargoLectorController = TextEditingController();
  final cargoMantenimientoController = TextEditingController();
  final cargoOtrosController = TextEditingController();
  final diasVencimientoController = TextEditingController();
  final moraBaseController = TextEditingController();

  List<Map<String, dynamic>> tarifas = [];
  Map<String, dynamic> configuracion = {};

  bool cargando = false;
  bool guardandoConfiguracion = false;
  int? procesandoTarifaId;
  String error = '';

  @override
  void initState() {
    super.initState();
    cargarTodo();
  }

  @override
  void dispose() {
    cargoLectorController.dispose();
    cargoMantenimientoController.dispose();
    cargoOtrosController.dispose();
    diasVencimientoController.dispose();
    moraBaseController.dispose();
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
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _entero(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _id(Map<String, dynamic> tarifa) {
    return _entero(tarifa['id'] ?? tarifa['idTarifa']);
  }

  double _desde(Map<String, dynamic> tarifa) {
    return _num(tarifa['consumoDesde'] ?? tarifa['desde']);
  }

  double? _hasta(Map<String, dynamic> tarifa) {
    final value = tarifa['consumoHasta'] ?? tarifa['hasta'];
    if (value == null) return null;

    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty ||
        text == 'null' ||
        text == '∞' ||
        text == 'infinity') {
      return null;
    }

    return double.tryParse(text);
  }

  double _precio(Map<String, dynamic> tarifa) {
    return _num(
      tarifa['precioM3'] ?? tarifa['precio'] ?? tarifa['monto'],
    );
  }

  bool _activo(Map<String, dynamic> tarifa) {
    final value = tarifa['estado'];
    if (value is bool) return value;
    if (value == null) return true;

    final text = value.toString().trim().toLowerCase();
    return text == 'true' ||
        text == 'activo' ||
        text == 'activa' ||
        text == '1';
  }

  String _formato(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(3);
  }

  String _nombre(Map<String, dynamic> tarifa) {
    final value = _txt(
      tarifa['nombreTarifa'] ?? tarifa['nombre'],
      '',
    );

    if (value.isNotEmpty) return value;

    final hasta = _hasta(tarifa);
    if (hasta == null) return 'Mayor a ${_formato(_desde(tarifa))} m³';

    return 'Desde ${_formato(_desde(tarifa))} '
        'hasta ${_formato(hasta)} m³';
  }

  String _rango(Map<String, dynamic> tarifa) {
    final hasta = _hasta(tarifa);
    if (hasta == null) return '${_formato(_desde(tarifa))} m³ a más';

    return '${_formato(_desde(tarifa))} m³ - ${_formato(hasta)} m³';
  }

  double _configNum(String key, [double fallback = 0]) {
    if (!configuracion.containsKey(key)) return fallback;
    return _num(configuracion[key]);
  }

  int _configInt(String key, [int fallback = 0]) {
    if (!configuracion.containsKey(key)) return fallback;
    return _entero(configuracion[key], fallback);
  }

  int get totalTarifas => tarifas.length;

  int get tarifasActivas => tarifas.where(_activo).length;

  double get cargosBase =>
      _configNum('cargoLector') +
      _configNum('cargoMantenimiento') +
      _configNum('cargoOtros') +
      _configNum('moraBase');

  double get precioPromedio {
    final activas = tarifas.where(_activo).toList();
    final fuente = activas.isNotEmpty ? activas : tarifas;
    if (fuente.isEmpty) return 0;

    return fuente.fold<double>(
          0,
          (total, tarifa) => total + _precio(tarifa),
        ) /
        fuente.length;
  }

  double get precioMaximo {
    if (tarifas.isEmpty) return 1;
    final values = tarifas.map(_precio).where((value) => value > 0).toList();
    if (values.isEmpty) return 1;
    values.sort();
    return values.last;
  }

  Future<void> cargarTodo() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final tarifasResponse = await tarifaService.listarTarifas();
      final configuracionResponse =
          await tarifaService.obtenerConfiguracionCobranza();

      tarifasResponse.sort(
        (a, b) => _desde(a).compareTo(_desde(b)),
      );

      if (!mounted) return;

      setState(() {
        tarifas = tarifasResponse;
        configuracion = configuracionResponse;
        cargando = false;
      });

      _llenarConfiguracion();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _llenarConfiguracion() {
    cargoLectorController.text =
        _configNum('cargoLector', 3).toStringAsFixed(2);
    cargoMantenimientoController.text =
        _configNum('cargoMantenimiento', 3).toStringAsFixed(2);
    cargoOtrosController.text =
        _configNum('cargoOtros', 0.25).toStringAsFixed(2);
    diasVencimientoController.text =
        _configInt('diasVencimiento', 15).toString();
    moraBaseController.text =
        _configNum('moraBase', 2).toStringAsFixed(2);
  }

  Future<void> guardarConfiguracion() async {
    final cargoLector =
        double.tryParse(cargoLectorController.text.trim());
    final cargoMantenimiento =
        double.tryParse(cargoMantenimientoController.text.trim());
    final cargoOtros =
        double.tryParse(cargoOtrosController.text.trim());
    final diasVencimiento =
        int.tryParse(diasVencimientoController.text.trim());
    final moraBase =
        double.tryParse(moraBaseController.text.trim());

    if (cargoLector == null ||
        cargoMantenimiento == null ||
        cargoOtros == null ||
        diasVencimiento == null ||
        moraBase == null) {
      _mensaje('Completa todos los datos de cobranza.', true);
      return;
    }

    if (cargoLector < 0 ||
        cargoMantenimiento < 0 ||
        cargoOtros < 0 ||
        moraBase < 0) {
      _mensaje('Los cargos no pueden ser negativos.', true);
      return;
    }

    if (diasVencimiento <= 0) {
      _mensaje(
        'Los días de vencimiento deben ser mayores a cero.',
        true,
      );
      return;
    }

    setState(() => guardandoConfiguracion = true);

    try {
      final response =
          await tarifaService.actualizarConfiguracionCobranza(
        cargoLector: cargoLector,
        cargoMantenimiento: cargoMantenimiento,
        cargoOtros: cargoOtros,
        diasVencimiento: diasVencimiento,
        moraBase: moraBase,
      );

      if (!mounted) return;

      setState(() {
        configuracion = response;
        guardandoConfiguracion = false;
      });

      _llenarConfiguracion();
      _mensaje('Configuración guardada correctamente.', false);
    } catch (e) {
      if (!mounted) return;

      setState(() => guardandoConfiguracion = false);
      _mensaje(
        e.toString().replaceFirst('Exception: ', ''),
        true,
      );
    }
  }

  Future<void> _guardarTarifa({
    Map<String, dynamic>? tarifa,
    required Map<String, dynamic> payload,
  }) async {
    if (tarifa == null) {
      await tarifaService.registrarTarifa(payload);
      return;
    }

    final id = _id(tarifa);
    if (id <= 0) throw Exception('No se encontró el ID de la tarifa.');

    await tarifaService.actualizarTarifa(
      idTarifa: id,
      data: payload,
    );
  }

  void _abrirFormulario({Map<String, dynamic>? tarifa}) {
    final nombreController = TextEditingController(
      text: tarifa == null ? '' : _nombre(tarifa),
    );
    final desdeController = TextEditingController(
      text: tarifa == null ? '' : _formato(_desde(tarifa)),
    );
    final hastaController = TextEditingController(
      text: tarifa == null || _hasta(tarifa) == null
          ? ''
          : _formato(_hasta(tarifa)!),
    );
    final precioController = TextEditingController(
      text: tarifa == null ? '' : _precio(tarifa).toStringAsFixed(2),
    );

    bool estado = tarifa == null ? true : _activo(tarifa);
    bool guardando = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.jassSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> guardar() async {
              final nombre = nombreController.text.trim();
              final desde =
                  double.tryParse(desdeController.text.trim());
              final hastaTexto = hastaController.text.trim();
              final hasta = hastaTexto.isEmpty
                  ? null
                  : double.tryParse(hastaTexto);
              final precio =
                  double.tryParse(precioController.text.trim());

              if (nombre.isEmpty) {
                _mensaje('Ingresa el nombre de la tarifa.', true);
                return;
              }

              if (desde == null || desde < 0) {
                _mensaje('Ingresa un consumo inicial válido.', true);
                return;
              }

              if (hastaTexto.isNotEmpty && hasta == null) {
                _mensaje('Ingresa un consumo final válido.', true);
                return;
              }

              if (hasta != null && hasta <= desde) {
                _mensaje(
                  'El consumo final debe ser mayor al inicial.',
                  true,
                );
                return;
              }

              if (precio == null || precio < 0) {
                _mensaje('Ingresa un precio válido.', true);
                return;
              }

              setSheetState(() => guardando = true);

              try {
                await _guardarTarifa(
                  tarifa: tarifa,
                  payload: {
                    'nombreTarifa': nombre,
                    'consumoDesde': desde,
                    'consumoHasta': hasta,
                    'precioM3': precio,
                    'estado': estado,
                  },
                );

                if (!mounted) return;

                Navigator.pop(sheetContext);

                _mensaje(
                  tarifa == null
                      ? 'Tarifa registrada correctamente.'
                      : 'Tarifa actualizada correctamente.',
                  false,
                );

                await cargarTodo();
              } catch (e) {
                if (!mounted) return;

                setSheetState(() => guardando = false);
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
                bottom:
                    MediaQuery.of(sheetContext).viewInsets.bottom + 22,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarifa == null ? 'Nueva tarifa' : 'Editar tarifa',
                      style: TextStyle(
                        color: context.jassTextPrimary,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Configura el tramo de consumo y el precio por m³.',
                      style: TextStyle(
                        color: context.jassTextMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 18),
                    _Field(
                      controller: nombreController,
                      label: 'Nombre de tarifa',
                      keyboardType: TextInputType.text,
                    ),
                    _Field(
                      controller: desdeController,
                      label: 'Consumo desde m³',
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    _Field(
                      controller: hastaController,
                      label: 'Consumo hasta m³ (vacío si no tiene límite)',
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    _Field(
                      controller: precioController,
                      label: 'Precio por m³ S/',
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Estado',
                            style: TextStyle(
                              color: context.jassTextPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        ChoiceChip(
                          selected: estado,
                          selectedColor: Color(0xFFEAF8EF),
                          backgroundColor: Color(0xFFFFECEC),
                          label: Text(
                            estado ? 'Activa' : 'Inactiva',
                            style: TextStyle(
                              color: estado
                                  ? JassColors.success
                                  : JassColors.danger,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          onSelected: (_) {
                            setSheetState(() => estado = !estado);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: guardando ? null : guardar,
                        icon: guardando
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.save_outlined),
                        label: Text(
                          guardando ? 'Guardando...' : 'Guardar cambios',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JassColors.secondary,
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
    ).whenComplete(() {
      nombreController.dispose();
      desdeController.dispose();
      hastaController.dispose();
      precioController.dispose();
    });
  }

  Future<void> _cambiarEstado(Map<String, dynamic> tarifa) async {
    final id = _id(tarifa);
    if (id <= 0) {
      _mensaje('No se encontró el ID de la tarifa.', true);
      return;
    }

    final nuevoEstado = !_activo(tarifa);

    final confirmado = await _confirmar(
      titulo: nuevoEstado ? 'Activar tarifa' : 'Desactivar tarifa',
      mensaje:
          '¿Deseas ${nuevoEstado ? 'activar' : 'desactivar'} '
          '"${_nombre(tarifa)}"?',
      textoConfirmar: nuevoEstado ? 'Activar' : 'Desactivar',
      color: nuevoEstado ? JassColors.success : JassColors.warning,
    );

    if (!confirmado) return;

    setState(() => procesandoTarifaId = id);

    try {
      await tarifaService.cambiarEstadoTarifa(
        idTarifa: id,
        estado: nuevoEstado,
      );

      if (!mounted) return;

      _mensaje(
        nuevoEstado
            ? 'Tarifa activada correctamente.'
            : 'Tarifa desactivada correctamente.',
        false,
      );

      await cargarTodo();
    } catch (e) {
      if (!mounted) return;
      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    } finally {
      if (mounted) setState(() => procesandoTarifaId = null);
    }
  }

  Future<void> _eliminar(Map<String, dynamic> tarifa) async {
    final id = _id(tarifa);
    if (id <= 0) {
      _mensaje('No se encontró el ID de la tarifa.', true);
      return;
    }

    final confirmado = await _confirmar(
      titulo: 'Eliminar tarifa',
      mensaje:
          '¿Deseas eliminar "${_nombre(tarifa)}"? '
          'Esta acción no se puede deshacer.',
      textoConfirmar: 'Eliminar',
      color: JassColors.danger,
    );

    if (!confirmado) return;

    setState(() => procesandoTarifaId = id);

    try {
      await tarifaService.eliminarTarifa(idTarifa: id);

      if (!mounted) return;

      _mensaje('Tarifa eliminada correctamente.', false);
      await cargarTodo();
    } catch (e) {
      if (!mounted) return;
      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    } finally {
      if (mounted) setState(() => procesandoTarifaId = null);
    }
  }

  Future<bool> _confirmar({
    required String titulo,
    required String mensaje,
    required String textoConfirmar,
    required Color color,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: context.jassSurface,
          title: Text(
            titulo,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            mensaje,
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text(textoConfirmar),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  void _mensaje(String mensaje, bool esError) {
    if (!mounted) return;

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
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/admin-clientes');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/admin-recibos');
    }
  }

  void _abrirMenu() {
    showAdminQuickMenu(
      context: context,
      onRefresh: cargarTodo,
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 2,
        onTap: _go,
        onPlus: _abrirMenu,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarTodo,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                SizedBox(height: 18),
                if (cargando)
                  _loading()
                else if (error.isNotEmpty)
                  _ErrorCard(error: error, onRetry: cargarTodo)
                else ...[
                  _resumen(),
                  SizedBox(height: 18),
                  _configuracionCard(),
                  SizedBox(height: 18),
                  _analisisCard(),
                  SizedBox(height: 18),
                  _tarifasCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tarifas de pago',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _IconButtonBox(
          icon: Icons.refresh_rounded,
          tooltip: 'Actualizar',
          onTap: cargarTodo,
        ),
        SizedBox(width: 10),
        _IconButtonBox(
          icon: Icons.add_rounded,
          tooltip: 'Nueva tarifa',
          primary: true,
          onTap: () => _abrirFormulario(),
        ),
      ],
    );
  }

  Widget _loading() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Cargando tarifas y configuración...',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumen() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.18,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          icon: Icons.receipt_long_rounded,
          title: 'Total tarifas',
          value: '$totalTarifas',
          subtitle: 'Tramos registrados',
          iconColor: JassColors.secondary,
        ),
        _SummaryCard(
          icon: Icons.check_rounded,
          title: 'Tarifas activas',
          value: '$tarifasActivas',
          subtitle: 'Disponibles para cálculo',
          iconColor: JassColors.success,
        ),
        _SummaryCard(
          icon: Icons.attach_money_rounded,
          title: 'Cargos base',
          value: 'S/ ${cargosBase.toStringAsFixed(2)}',
          subtitle: 'Lector + mantenimiento + otros + mora',
          iconColor: JassColors.warning,
        ),
        _SummaryCard(
          icon: Icons.water_drop_outlined,
          title: 'Precio promedio',
          value: 'S/ ${precioPromedio.toStringAsFixed(2)}',
          subtitle: 'Promedio por m³',
          iconColor: JassColors.secondary,
        ),
      ],
    );
  }

  Widget _configuracionCard() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Tag(text: 'Configuración de cobranza'),
          SizedBox(height: 12),
          Text(
            'Cargos aplicados automáticamente',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'El administrador define estos montos. '
            'El lecturador solo registra la lectura actual.',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          SizedBox(height: 18),
          _Field(
            controller: cargoLectorController,
            label: 'Cargo lector S/',
            icon: Icons.badge_outlined,
          ),
          _Field(
            controller: cargoMantenimientoController,
            label: 'Cargo mantenimiento S/',
            icon: Icons.build_outlined,
          ),
          _Field(
            controller: cargoOtrosController,
            label: 'Otros cargos S/',
            icon: Icons.add_card_rounded,
          ),
          _Field(
            controller: diasVencimientoController,
            label: 'Días de vencimiento',
            icon: Icons.event_rounded,
            keyboardType: TextInputType.number,
          ),
          _Field(
            controller: moraBaseController,
            label: 'Mora base S/',
            icon: Icons.warning_amber_rounded,
          ),
          SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: guardandoConfiguracion
                  ? null
                  : guardarConfiguracion,
              icon: guardandoConfiguracion
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.save_outlined),
              label: Text(
                guardandoConfiguracion
                    ? 'Guardando...'
                    : 'Guardar configuración',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: JassColors.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _MiniCard(
                label: 'Cargo lector',
                value:
                    'S/ ${_configNum('cargoLector', 3).toStringAsFixed(2)}',
              ),
              _MiniCard(
                label: 'Mantenimiento',
                value:
                    'S/ ${_configNum('cargoMantenimiento', 3).toStringAsFixed(2)}',
              ),
              _MiniCard(
                label: 'Otros cargos',
                value:
                    'S/ ${_configNum('cargoOtros', 0.25).toStringAsFixed(2)}',
              ),
              _MiniCard(
                label: 'Vencimiento',
                value:
                    '${_configInt('diasVencimiento', 15)} días',
              ),
              _MiniCard(
                label: 'Mora base',
                value:
                    'S/ ${_configNum('moraBase', 2).toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _analisisCard() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallTitle(text: 'ANÁLISIS'),
          SizedBox(height: 6),
          Text(
            'Precios por tramo de consumo',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 16),
          if (tarifas.isEmpty)
            Text(
              'No hay tarifas para analizar.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...tarifas.map(
              (tarifa) => _RangeBar(
                name: _nombre(tarifa),
                range: _rango(tarifa),
                price: _precio(tarifa),
                active: _activo(tarifa),
                progress: (_precio(tarifa) / precioMaximo)
                    .clamp(0.0, 1.0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarifasCard() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SmallTitle(text: 'REGISTROS'),
                    SizedBox(height: 6),
                    Text(
                      'Tarifas registradas',
                      style: TextStyle(
                        color: context.jassTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${tarifas.length} resultado(s)',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          if (tarifas.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No hay tarifas registradas.'),
              ),
            )
          else
            ...tarifas.map(
              (tarifa) => _TariffCard(
                name: _nombre(tarifa),
                range: _rango(tarifa),
                from: _desde(tarifa),
                to: _hasta(tarifa),
                price: _precio(tarifa),
                active: _activo(tarifa),
                processing: procesandoTarifaId == _id(tarifa),
                onEdit: () => _abrirFormulario(tarifa: tarifa),
                onToggle: () => _cambiarEstado(tarifa),
                onDelete: () => _eliminar(tarifa),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;

  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.jassBorder),
        boxShadow: [
          BoxShadow(
            color: context.jassShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconButtonBox extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool primary;

  const _IconButtonBox({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: primary ? JassColors.secondary : context.jassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              primary ? JassColors.secondary : context.jassBorder,
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(
          icon,
          color: primary ? Colors.white : context.jassTextPrimary,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.jassBorder),
        boxShadow: [
          BoxShadow(
            color: context.jassShadow,
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType =
        const TextInputType.numberWithOptions(decimal: true),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: context.jassTextPrimary,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.jassTextMuted),
          prefixIcon: icon == null
              ? null
              : Icon(icon, color: JassColors.secondary),
          filled: true,
          fillColor: context.jassSurfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: context.jassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: context.jassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: JassColors.secondary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: context.jassSelectedSurface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: JassColors.secondary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallTitle extends StatelessWidget {
  final String text;

  const _SmallTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: JassColors.secondary,
        fontSize: 11,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;

  const _MiniCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  final String name;
  final String range;
  final double price;
  final bool active;
  final double progress;

  const _RangeBar({
    required this.name,
    required this.range,
    required this.price,
    required this.active,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'S/ ${price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  range,
                  style: TextStyle(
                    color: context.jassTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                active ? 'Activa' : 'Inactiva',
                style: TextStyle(
                  color:
                      active ? JassColors.success : JassColors.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: context.jassBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                active ? JassColors.secondary : JassColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TariffCard extends StatelessWidget {
  final String name;
  final String range;
  final double from;
  final double? to;
  final double price;
  final bool active;
  final bool processing;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TariffCard({
    required this.name,
    required this.range,
    required this.from,
    required this.to,
    required this.price,
    required this.active,
    required this.processing,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  String _value(double number) {
    if (number % 1 == 0) return number.toStringAsFixed(0);
    return number.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Status(active: active),
            ],
          ),
          SizedBox(height: 6),
          Text(
            range,
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Data(label: 'Desde', value: '${_value(from)} m³'),
              _Data(
                label: 'Hasta',
                value: to == null ? 'A más' : '${_value(to!)} m³',
              ),
              _Data(
                label: 'Precio',
                value: 'S/ ${price.toStringAsFixed(2)}',
              ),
            ],
          ),
          SizedBox(height: 14),
          if (processing)
            Center(child: CircularProgressIndicator())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text('Editar'),
                ),
                OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    active
                        ? Icons.power_settings_new_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text(active ? 'Desactivar' : 'Activar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: active
                        ? JassColors.warning
                        : JassColors.success,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: JassColors.danger,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final bool active;

  const _Status({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Color(0xFFEAF8EF) : Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        active ? 'ACTIVA' : 'INACTIVA',
        style: TextStyle(
          color: active ? JassColors.success : JassColors.danger,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Data extends StatelessWidget {
  final String label;
  final String value;

  const _Data({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.jassBorder),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: context.jassTextPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
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
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFFFD1D1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: JassColors.danger,
            size: 40,
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
          SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
