import 'package:flutter/material.dart';

import '../../core/services/lecturador_service.dart';
import '../../core/services/lectura_offline_service.dart';
import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import '../../shared/widgets/admin_bottom_nav.dart';
import '../../shared/widgets/lector_bottom_nav.dart';

class BuscarSuministroPage extends StatefulWidget {
  final bool modoAdmin;

  const BuscarSuministroPage({
    super.key,
    this.modoAdmin = false,
  });

  @override
  State<BuscarSuministroPage> createState() =>
      _BuscarSuministroPageState();
}

class _BuscarSuministroPageState extends State<BuscarSuministroPage> {
  final LecturadorService lecturadorService = LecturadorService();
  final LecturaOfflineService lecturaOfflineService = LecturaOfflineService();
  final TextEditingController codigoController = TextEditingController();

  bool buscando = false;
  bool argumentoProcesado = false;

  String error = '';
  Map<String, dynamic>? suministro;

  Color get primary => context.jassTextPrimary;
  Color get muted => context.jassTextMuted;

  static const Color secondary = JassColors.secondary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (argumentoProcesado) return;
    argumentoProcesado = true;

    final argumentos = ModalRoute.of(context)?.settings.arguments;

    String codigoInicial = '';

    if (argumentos is String) {
      codigoInicial = argumentos.trim();
    } else if (argumentos is Map) {
      codigoInicial = _txt(
        argumentos['codigoSuministro'] ??
            argumentos['codigo'] ??
            argumentos['suministroCodigo'],
        '',
      );
    }

    if (codigoInicial.isEmpty) return;

    codigoController.text = codigoInicial.toUpperCase();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      buscarSuministro();
    });
  }

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  String _codigoSuministro(Map<String, dynamic> data) {
    return _txt(
      data['codigoSuministro'] ??
          data['suministroCodigo'] ??
          data['codigo'] ??
          data['numeroSuministro'],
      'SIN-CÓDIGO',
    );
  }

  String _titular(Map<String, dynamic> data) {
    return _txt(
      data['titular'] ??
          data['cliente'] ??
          data['nombreCliente'] ??
          data['nombres'] ??
          data['usuario'],
      'Usuario del servicio',
    );
  }

  String _direccion(Map<String, dynamic> data) {
    return _txt(
      data['direccionSuministro'] ??
          data['direccion'] ??
          data['direccionCliente'],
      'Dirección no registrada',
    );
  }

  String _sector(Map<String, dynamic> data) {
    return _txt(
      data['nombreSector'] ??
          data['sector'] ??
          data['sectorNombre'],
      'Huacariz',
    );
  }

  double _lecturaAnterior(Map<String, dynamic> data) {
    final value = data['lecturaAnterior'] ??
        data['ultimaLectura'] ??
        data['lecturaActual'] ??
        data['lecturaInicial'] ??
        0;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0.0;
  }

  bool _activo(Map<String, dynamic> data) {
    final value = data['estado'] ?? data['activo'];

    if (value is bool) return value;

    if (value == null) return true;

    final text = value.toString().toLowerCase().trim();

    return text == 'true' ||
        text == 'activo' ||
        text == '1';
  }

  Future<void> escanearQr() async {
    if (buscando) return;

    if (widget.modoAdmin) {
      // Reemplaza esta pantalla por el escáner administrativo.
      // Cuando lea el QR, regresará a /admin-buscar-suministro.
      Navigator.pushReplacementNamed(
        context,
        '/admin-qr-scanner',
      );
      return;
    }

    // En modo lecturador, el escáner devuelve el código con Navigator.pop.
    final codigo = await Navigator.pushNamed(
      context,
      '/qr-scanner',
    );

    if (!mounted || codigo == null) return;

    final codigoTexto =
        codigo.toString().trim().toUpperCase();

    if (codigoTexto.isEmpty) return;

    codigoController.text = codigoTexto;

    await buscarSuministro();
  }

  Future<void> buscarSuministro() async {
    final codigo =
        codigoController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      _mensaje(
        'Ingresa el código del suministro.',
        esError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    codigoController.text = codigo;

    setState(() {
      buscando = true;
      error = '';
      suministro = null;
    });

    try {
      final data = widget.modoAdmin
          ? await lecturadorService.buscarSuministro(codigo)
          : await lecturaOfflineService.buscarSuministro(codigo);

      if (!mounted) return;

      if (data.isEmpty) {
        setState(() {
          error =
              'No se encontró información del suministro.';
          buscando = false;
        });
        return;
      }

      setState(() {
        suministro = data;
        buscando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error =
            e.toString().replaceFirst('Exception: ', '');
        buscando = false;
      });
    }
  }

  void limpiarBusqueda() {
    codigoController.clear();

    setState(() {
      suministro = null;
      error = '';
      buscando = false;
    });
  }

  String _tipoOperacion(Map<String, dynamic> data) {
    final estado = _txt(
      data['estadoInstalacion'],
      'PENDIENTE_INSTALACION',
    ).toUpperCase();
    return estado == 'INSTALADO' ? 'LECTURA' : 'MANTENIMIENTO';
  }

  bool _permiteOperacion(Map<String, dynamic> data) {
    if (!_activo(data)) return false;
    final tipo = _tipoOperacion(data);
    final value = tipo == 'LECTURA'
        ? data['permiteRegistrarLectura']
        : data['permiteGenerarMantenimiento'];
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true' || value == 1;
  }

  void irRegistrarLectura() {
    final data = suministro;

    if (data == null) {
      _mensaje(
        'Primero busca un suministro.',
        esError: true,
      );
      return;
    }

    Navigator.pushNamed(
      context,
      widget.modoAdmin
          ? '/admin-registrar-lectura'
          : '/registrar-lectura',
      arguments: {
        ...data,
        'tipoOperacion': _tipoOperacion(data),
      },
    );
  }

  void _mensaje(
    String mensaje, {
    required bool esError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError
            ? JassColors.danger
            : JassColors.success,
      ),
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

  // =========================================================
  // NAVEGACIÓN ADMINISTRADOR
  // =========================================================

  void _goBottomAdmin(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(
        context,
        '/admin-dashboard',
      );
    }

    if (index == 1) {
      Navigator.pushReplacementNamed(
        context,
        '/admin-clientes',
      );
    }

    if (index == 2) {
      Navigator.pushReplacementNamed(
        context,
        '/admin-tarifas',
      );
    }

    if (index == 3) {
      Navigator.pushReplacementNamed(
        context,
        '/admin-recibos',
      );
    }
  }

  void _abrirMenuAdmin() {
    showAdminQuickMenu(
      context: context,
      onRefresh: codigoController.text.trim().isEmpty
          ? null
          : buscarSuministro,
    );
  }

  // =========================================================
  // NAVEGACIÓN LECTURADOR
  // =========================================================

  void _goBottomLector(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(
        context,
        '/lector-home',
      );
    }

    if (index == 1) return;

    if (index == 2) {
      escanearQr();
    }

    if (index == 3) {
      Navigator.pushReplacementNamed(
        context,
        '/historial-lecturas',
      );
    }
  }

  void _abrirMenuLector() {
    showLectorQuickMenu(
      context: context,
      onRefresh: codigoController.text.trim().isEmpty
          ? null
          : buscarSuministro,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,

      // El administrador mantiene su propia barra.
      // El lecturador conserva la barra del módulo de lecturas.
      bottomNavigationBar: widget.modoAdmin
          ? AdminBottomNav(
              currentIndex: -1,
              onTap: _goBottomAdmin,
              onPlus: _abrirMenuAdmin,
            )
          : LectorBottomNav(
              currentIndex: 1,
              onTap: _goBottomLector,
              onPlus: _abrirMenuLector,
            ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: codigoController.text.trim().isEmpty
              ? () async {}
              : buscarSuministro,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSearchCard(),
                const SizedBox(height: 18),

                if (buscando)
                  _buildLoading(),

                if (error.isNotEmpty && !buscando)
                  _ErrorCard(
                    error: error,
                    onRetry: buscarSuministro,
                  ),

                if (suministro != null && !buscando)
                  _SuministroCard(
                    codigo:
                        _codigoSuministro(suministro!),
                    titular: _titular(suministro!),
                    direccion: _direccion(suministro!),
                    sector: _sector(suministro!),
                    lecturaAnterior:
                        _lecturaAnterior(suministro!),
                    activo: _activo(suministro!),
                    habilitado: _permiteOperacion(suministro!),
                    accion: _tipoOperacion(suministro!) == 'LECTURA'
                        ? 'Registrar lectura'
                        : 'Generar solo mantenimiento',
                    offline: suministro!['origenOffline'] == true,
                    onRegistrar: irRegistrarLectura,
                  ),
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
            border: Border.all(
              color: context.jassBorder,
            ),
          ),
          child: IconButton(
            onPressed: _volverInicio,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: primary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
              const SizedBox(height: 4),
              Text(
                'Buscar suministro',
                style: TextStyle(
                  color: primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (suministro != null ||
            error.isNotEmpty ||
            codigoController.text.isNotEmpty)
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.jassSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.jassBorder,
              ),
            ),
            child: IconButton(
              onPressed:
                  buscando ? null : limpiarBusqueda,
              icon: const Icon(
                Icons.refresh_rounded,
                color: secondary,
              ),
              tooltip: 'Nueva búsqueda',
            ),
          ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.jassBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: context.jassShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Código de suministro',
            style: TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.modoAdmin
                ? 'Ingresa o escanea el código para consultar el suministro desde el panel administrativo.'
                : 'Ingresa o escanea el código QR del suministro para registrar una nueva lectura.',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: codigoController,
            enabled: !buscando,
            textCapitalization:
                TextCapitalization.characters,
            textInputAction:
                TextInputAction.search,
            onChanged: (_) {
              setState(() {});
            },
            onSubmitted: (_) {
              buscarSuministro();
            },
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: 'Ejemplo: SUM-001',
              hintStyle: TextStyle(
                color: muted,
              ),
              prefixIcon: const Icon(
                Icons.water_drop_rounded,
                color: secondary,
              ),
              suffixIcon: IconButton(
                onPressed:
                    buscando ? null : escanearQr,
                icon: const Icon(
                  Icons.camera_alt_rounded,
                ),
                tooltip: 'Escanear QR',
              ),
              filled: true,
              fillColor: context.jassSurfaceAlt,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: context.jassBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: context.jassBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: secondary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed:
                  buscando ? null : escanearQr,
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
              ),
              label: Text(
                widget.modoAdmin
                    ? 'Escanear QR como administrador'
                    : 'Escanear QR con cámara',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                backgroundColor:
                    context.jassSurface,
                side: BorderSide(
                  color: context.jassBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  buscando ? null : buscarSuministro,
              icon: buscando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.search_rounded,
                    ),
              label: Text(
                buscando
                    ? 'Buscando...'
                    : 'Buscar suministro',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    secondary.withValues(alpha: 0.55),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(
            'Buscando suministro...',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuministroCard extends StatelessWidget {
  final String codigo;
  final String titular;
  final String direccion;
  final String sector;
  final double lecturaAnterior;
  final bool activo;
  final bool habilitado;
  final bool offline;
  final String accion;
  final VoidCallback onRegistrar;

  const _SuministroCard({
    required this.codigo,
    required this.titular,
    required this.direccion,
    required this.sector,
    required this.lecturaAnterior,
    required this.activo,
    required this.habilitado,
    required this.offline,
    required this.accion,
    required this.onRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary =
        context.jassTextPrimary;
    final Color muted =
        context.jassTextMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.jassBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: context.jassShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    context.jassSelectedSurface,
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: JassColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  codigo,
                  style: TextStyle(
                    color: primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _EstadoChip(activo: activo),
            ],
          ),
          if (offline) ...[
            const SizedBox(height: 10),
            const _OfflineBadge(),
          ],
          const SizedBox(height: 16),
          _InfoLine(
            label: 'Titular',
            value: titular,
          ),
          _InfoLine(
            label: 'Dirección',
            value: direccion,
          ),
          _InfoLine(
            label: 'Sector',
            value: sector,
          ),
          _InfoLine(
            label: 'Última lectura',
            value:
                '${lecturaAnterior.toStringAsFixed(3)} m³',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: habilitado ? onRegistrar : null,
              icon: const Icon(
                Icons.edit_note_rounded,
              ),
              label: Text(
                accion,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    JassColors.secondary,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor:
                    context.jassBorder,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (!activo) ...[
            const SizedBox(height: 10),
            Text(
              'El suministro se encuentra inactivo.',
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
    final Color primary =
        context.jassTextPrimary;
    final Color muted =
        context.jassTextMuted;

    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 9),
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
          const SizedBox(width: 12),
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

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2D8),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 15, color: Color(0xFF9A6500)),
          SizedBox(width: 6),
          Text(
            'DATOS GUARDADOS EN EL CELULAR',
            style: TextStyle(
              color: Color(0xFF9A6500),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final bool activo;

  const _EstadoChip({
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
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
          const Icon(
            Icons.error_outline_rounded,
            color: JassColors.danger,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: JassColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}