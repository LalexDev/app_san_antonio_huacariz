import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/canal_pago_service.dart';
import '../../core/services/pago_service.dart';
import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import '../../shared/widgets/cliente_bottom_nav.dart';

class PagoCipPage extends StatefulWidget {
  const PagoCipPage({super.key});

  @override
  State<PagoCipPage> createState() => _PagoCipPageState();
}

class _PagoCipPageState extends State<PagoCipPage> {
  final PagoService pagoService = PagoService();
  final CanalPagoService canalPagoService = CanalPagoService();
  final TextEditingController codigoOperacionController =
      TextEditingController();
  final ImagePicker imagePicker = ImagePicker();

  Map<String, dynamic> recibo = {};
  List<Map<String, dynamic>> canales = [];

  bool argumentosCargados = false;
  bool cargandoCanales = false;
  bool procesando = false;
  String error = '';
  String metodoPago = 'YAPE';
  XFile? comprobante;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (argumentosCargados) return;
    argumentosCargados = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      recibo = args;
    } else if (args is Map) {
      recibo = Map<String, dynamic>.from(args);
    }

    _cargarCanales();
  }

  @override
  void dispose() {
    codigoOperacionController.dispose();
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

  int _idRecibo() {
    final value = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _codigoRecibo() {
    return _txt(
      recibo['codigoRecibo'] ?? recibo['numeroRecibo'] ?? recibo['codigo'],
      'REC-${_idRecibo()}',
    );
  }

  String _codigoSuministro() {
    return _txt(
      recibo['codigoSuministro'] ??
          recibo['suministroCodigo'] ??
          recibo['numeroSuministro'],
      'SIN-CÓDIGO',
    );
  }

  String _estado() {
    return _txt(
      recibo['estadoRecibo'] ?? recibo['estado'],
      'PENDIENTE',
    ).toUpperCase();
  }

  double _total() {
    return _num(
      recibo['total'] ??
          recibo['montoTotal'] ??
          recibo['importeTotal'] ??
          recibo['totalPagar'],
    );
  }

  String _periodo() {
    final anio = int.tryParse('${recibo['anio'] ?? DateTime.now().year}') ??
        DateTime.now().year;
    final mes = int.tryParse('${recibo['mes'] ?? DateTime.now().month}') ??
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

    return '${meses[(mes - 1).clamp(0, 11)]} $anio';
  }

  bool _puedePagar() {
    final estado = _estado();
    return estado == 'PENDIENTE' || estado == 'VENCIDO';
  }

  List<Map<String, dynamic>> get canalesVisibles {
    final filtrados = canales.where((canal) {
      final metodo = _txt(canal['metodoPago'], '').toUpperCase();
      return metodo == 'YAPE' ||
          metodo == 'PLIN' ||
          metodo == 'TRANSFERENCIA';
    }).toList();

    if (filtrados.isNotEmpty) return filtrados;

    return [
      {
        'metodoPago': 'YAPE',
        'titular': 'Agua Potable Huacariz',
        'descripcion': 'Realiza el pago y registra el número de operación.',
        'estado': true,
      },
      {
        'metodoPago': 'PLIN',
        'titular': 'Agua Potable Huacariz',
        'descripcion': 'Realiza el pago y registra el número de operación.',
        'estado': true,
      },
      {
        'metodoPago': 'TRANSFERENCIA',
        'titular': 'Agua Potable Huacariz',
        'descripcion': 'Los datos bancarios serán configurados por administración.',
        'estado': true,
      },
    ];
  }

  Map<String, dynamic>? get canalSeleccionado {
    for (final canal in canalesVisibles) {
      if (_txt(canal['metodoPago'], '').toUpperCase() == metodoPago) {
        return canal;
      }
    }
    return null;
  }

  Future<void> _cargarCanales() async {
    setState(() {
      cargandoCanales = true;
      error = '';
    });

    try {
      final data = await canalPagoService.listarActivos();
      if (!mounted) return;

      setState(() {
        canales = data;
        cargandoCanales = false;

        final disponibles = canalesVisibles;
        if (!disponibles.any(
          (item) => _txt(item['metodoPago'], '').toUpperCase() == metodoPago,
        )) {
          metodoPago = _txt(disponibles.first['metodoPago'], 'YAPE')
              .toUpperCase();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        cargandoCanales = false;
      });
    }
  }

  Future<void> _seleccionarComprobante() async {
    final archivo = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );

    if (archivo == null) return;

    final extension = archivo.name.split('.').last.toLowerCase();
    if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      _mensaje('Solo se permiten imágenes JPG, PNG o WEBP.', true);
      return;
    }

    final size = await File(archivo.path).length();
    if (size > 3 * 1024 * 1024) {
      _mensaje('La imagen no debe superar los 3 MB.', true);
      return;
    }

    setState(() {
      comprobante = archivo;
      error = '';
    });
  }

  Future<void> _registrarPago() async {
    final idRecibo = _idRecibo();
    final codigoOperacion = codigoOperacionController.text.trim();

    if (idRecibo <= 0) {
      _mensaje('No se encontró el recibo para pagar.', true);
      return;
    }

    if (!_puedePagar()) {
      _mensaje('Este recibo ya fue pagado o está en revisión.', true);
      return;
    }

    if (codigoOperacion.length < 4) {
      _mensaje('Ingresa un código de operación válido.', true);
      return;
    }

    if (comprobante == null) {
      _mensaje('Selecciona la captura del comprobante.', true);
      return;
    }

    setState(() {
      procesando = true;
      error = '';
    });

    try {
      await pagoService.pagarMiRecibo(
        idRecibo: idRecibo,
        metodoPago: metodoPago,
        codigoOperacion: codigoOperacion,
        comprobantePath: comprobante!.path,
      );

      if (!mounted) return;

      _mensaje(
        'Pago enviado para revisión. Administración validará la operación.',
        false,
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/recibos',
        (route) => route.settings.name == '/home',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        procesando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
      _mensaje(error, true);
    }
  }

  String _assetMetodo(String metodo) {
    switch (metodo.toUpperCase()) {
      case 'YAPE':
        return 'assets/images/pagos/yape.png';
      case 'PLIN':
        return 'assets/images/pagos/plin.png';
      default:
        return 'assets/images/pagos/transferencia.png';
    }
  }

  void _mensaje(String mensaje, bool esError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? JassColors.danger : JassColors.success,
      ),
    );
  }

  void _goBottom(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/recibos');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/perfil');
    }
  }

  void _abrirMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.jassSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_rounded),
                  title: const Text('Ir al inicio'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_rounded),
                  title: const Text('Mis recibos'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushReplacementNamed(context, '/recibos');
                  },
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
        currentIndex: 2,
        onTap: _goBottom,
        onPlus: _abrirMenu,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildHero(),
              const SizedBox(height: 18),
              if (!_puedePagar()) _buildEstadoBloqueado(),
              if (_puedePagar()) ...[
                _buildMetodos(),
                const SizedBox(height: 18),
                _buildCanal(),
                const SizedBox(height: 18),
                _buildFormulario(),
              ],
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
            border: Border.all(color: context.jassBorder),
          ),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back_rounded, color: context.jassTextPrimary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Portal cliente',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Pagar recibo',
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
          onPressed: cargandoCanales ? null : _cargarCanales,
          icon: const Icon(Icons.refresh_rounded),
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
          colors: [JassColors.primary, JassColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAGO DE AGUA POTABLE',
            style: TextStyle(
              color: Color(0xFFE7F8FF),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _codigoRecibo(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_periodo()} · ${_codigoSuministro()}',
            style: const TextStyle(
              color: Color(0xFFE7F8FF),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Total a pagar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'S/ ${_total().toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoBloqueado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        children: [
          Icon(
            _estado() == 'PAGADO'
                ? Icons.check_circle_rounded
                : Icons.schedule_rounded,
            color: _estado() == 'PAGADO'
                ? JassColors.success
                : JassColors.warning,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            _estado() == 'PAGADO'
                ? 'Este recibo ya fue pagado'
                : 'Pago en revisión',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodos() {
    return _Panel(
      title: 'Selecciona método de pago',
      child: Column(
        children: canalesVisibles.map((canal) {
          final metodo = _txt(canal['metodoPago'], '').toUpperCase();
          final seleccionado = metodo == metodoPago;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => metodoPago = metodo),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: seleccionado
                      ? context.jassSelectedSurface
                      : context.jassSurfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: seleccionado
                        ? JassColors.secondary
                        : context.jassBorder,
                    width: seleccionado ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 48,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Image.asset(
                        _assetMetodo(metodo),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metodo == 'TRANSFERENCIA'
                                ? 'Transferencia bancaria'
                                : metodo[0] + metodo.substring(1).toLowerCase(),
                            style: TextStyle(
                              color: context.jassTextPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _txt(
                              canal['descripcion'],
                              'Paga y registra el código de operación.',
                            ),
                            style: TextStyle(
                              color: context.jassTextMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: seleccionado
                              ? JassColors.secondary
                              : context.jassBorder,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: seleccionado
                                ? JassColors.secondary
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCanal() {
    final canal = canalSeleccionado;
    if (canal == null) return const SizedBox.shrink();

    final datos = <MapEntry<String, String>>[
      MapEntry('Titular', _txt(canal['titular'], 'Agua Potable Huacariz')),
      if (_txt(canal['numero'], '').isNotEmpty)
        MapEntry('Número', _txt(canal['numero'])),
      if (_txt(canal['banco'], '').isNotEmpty)
        MapEntry('Banco', _txt(canal['banco'])),
      if (_txt(canal['cuenta'], '').isNotEmpty)
        MapEntry('Cuenta', _txt(canal['cuenta'])),
      if (_txt(canal['cci'], '').isNotEmpty)
        MapEntry('CCI', _txt(canal['cci'])),
    ];

    return _Panel(
      title: 'Canal autorizado',
      child: Column(
        children: datos
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        item.key,
                        style: TextStyle(
                          color: context.jassTextMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: context.jassTextPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFormulario() {
    return _Panel(
      title: 'Enviar comprobante',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: codigoOperacionController,
            decoration: InputDecoration(
              labelText: 'Código / número de operación',
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
              filled: true,
              fillColor: context.jassSurfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: procesando ? null : _seleccionarComprobante,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.jassSurfaceAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.jassBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: JassColors.secondary,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comprobante == null
                              ? 'Seleccionar comprobante'
                              : comprobante!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.jassTextPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'JPG, PNG o WEBP · máximo 3 MB',
                          style: TextStyle(
                            color: context.jassTextMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (comprobante != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(comprobante!.path),
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: procesando ? null : _registrarPago,
              icon: procesando
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                procesando
                    ? 'Enviando a revisión...'
                    : 'Enviar pago para validación',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: JassColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
