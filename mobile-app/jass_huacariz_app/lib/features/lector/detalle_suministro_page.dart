import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import '../../shared/widgets/admin_bottom_nav.dart';
import '../../shared/widgets/lector_bottom_nav.dart';

class DetalleSuministroPage extends StatefulWidget {
  final bool modoAdmin;

  const DetalleSuministroPage({
    super.key,
    this.modoAdmin = false,
  });

  @override
  State<DetalleSuministroPage> createState() =>
      _DetalleSuministroPageState();
}

class _DetalleSuministroPageState extends State<DetalleSuministroPage> {
  Map<String, dynamic> suministro = {};
  bool inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (inicializado) return;
    inicializado = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      suministro = args;
    } else if (args is Map) {
      suministro = Map<String, dynamic>.from(args);
    }
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  String get codigo => _txt(
        suministro['codigoSuministro'] ??
            suministro['suministroCodigo'] ??
            suministro['codigo'] ??
            suministro['numeroSuministro'],
        'SIN-CÓDIGO',
      );

  String get titular => _txt(
        suministro['titular'] ??
            suministro['cliente'] ??
            suministro['nombreCliente'] ??
            suministro['nombres'] ??
            suministro['usuario'],
        'Usuario del servicio',
      );

  String get alias => _txt(
        suministro['aliasSuministro'] ?? suministro['alias'],
        'Sin alias',
      );

  String get sector => _txt(
        suministro['nombreSector'] ??
            suministro['sector'] ??
            suministro['sectorNombre'],
        'Sector no registrado',
      );

  String get direccion => _txt(
        suministro['direccionSuministro'] ??
            suministro['direccion'] ??
            suministro['direccionCliente'],
        'Dirección no registrada',
      );

  String get referencia => _txt(
        suministro['referencia'] ?? suministro['referenciaSuministro'],
        'Sin referencia',
      );

  String get lecturaAnterior => _txt(
        suministro['lecturaAnterior'] ??
            suministro['ultimaLectura'] ??
            suministro['lecturaActual'] ??
            suministro['lecturaInicial'],
        '0',
      );

  bool get activo {
    final value = suministro['estado'] ?? suministro['activo'];
    if (value is bool) return value;
    if (value == null) return true;
    final text = value.toString().trim().toUpperCase();
    return text == 'TRUE' || text == 'ACTIVO' || text == '1';
  }


  String get tipoOperacion {
    final estado = _txt(
      suministro['estadoInstalacion'],
      'PENDIENTE_INSTALACION',
    ).toUpperCase();
    return estado == 'INSTALADO' ? 'LECTURA' : 'MANTENIMIENTO';
  }

  bool get permiteOperacion {
    if (!activo) return false;
    final value = tipoOperacion == 'LECTURA'
        ? suministro['permiteRegistrarLectura']
        : suministro['permiteGenerarMantenimiento'];
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true' || value == 1;
  }

  String get textoOperacion => tipoOperacion == 'LECTURA'
      ? 'Registrar lectura'
      : 'Generar solo mantenimiento';

  void _registrar() {
    Navigator.pushNamed(
      context,
      widget.modoAdmin
          ? '/admin-registrar-lectura'
          : '/registrar-lectura',
      arguments: {
        ...suministro,
        'tipoOperacion': tipoOperacion,
      },
    );
  }

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      widget.modoAdmin
          ? '/admin-buscar-suministro'
          : '/buscar-suministro',
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
      Navigator.pushReplacementNamed(context, '/lector-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/buscar-suministro');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/qr-scanner');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/historial-lecturas');
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
              currentIndex: 1,
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
              const SizedBox(height: 18),
              _buildHero(),
              const SizedBox(height: 18),
              _buildDatos(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: permiteOperacion ? _registrar : null,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(
                    permiteOperacion ? textoOperacion : 'Operación no disponible',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JassColors.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.jassBorder,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
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
            onPressed: _volver,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.jassTextPrimary,
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
                  color: context.jassTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Detalle del suministro',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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
          colors: [JassColors.primary, JassColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      codigo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      titular,
                      style: const TextStyle(
                        color: Color(0xFFE7F8FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _EstadoChip(activo: activo),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            direccion,
            style: const TextStyle(
              color: Color(0xFFE7F8FF),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatos() {
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
            'Información del suministro',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Alias', value: alias),
          _InfoRow(label: 'Sector', value: sector),
          _InfoRow(label: 'Dirección', value: direccion),
          _InfoRow(label: 'Referencia', value: referencia),
          _InfoRow(label: 'Lectura anterior', value: lecturaAnterior),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.jassBorder),
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
          const SizedBox(width: 12),
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

class _EstadoChip extends StatelessWidget {
  final bool activo;

  const _EstadoChip({required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: activo
            ? const Color(0xFFEAF8EF)
            : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        activo ? 'ACTIVO' : 'INACTIVO',
        style: TextStyle(
          color: activo ? JassColors.success : JassColors.danger,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
