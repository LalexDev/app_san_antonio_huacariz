// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations
import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/sector_service.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminSectoresPage extends StatefulWidget {
  const AdminSectoresPage({super.key});

  @override
  State<AdminSectoresPage> createState() => _AdminSectoresPageState();
}

class _AdminSectoresPageState extends State<AdminSectoresPage> {
  final Color secondary = JassColors.secondary;
  final SectorService sectorService = SectorService();

  List<Map<String, dynamic>> sectores = [];
  bool cargando = false;
  String error = '';
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarSectores();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  int _idSector(Map<String, dynamic> sector) {
    final value = sector['id'] ?? sector['idSector'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _nombre(Map<String, dynamic> sector) {
    return _txt(sector['nombre'] ?? sector['nombreSector'], 'Sector');
  }

  String _descripcion(Map<String, dynamic> sector) {
    return _txt(sector['descripcion'], 'Sin descripción');
  }

  bool _estado(Map<String, dynamic> sector) {
    final value = sector['estado'];
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true' ||
        value.toString().toLowerCase() == 'activo';
  }

  List<Map<String, dynamic>> get sectoresFiltrados {
    final query = busqueda.trim().toLowerCase();

    if (query.isEmpty) return sectores;

    return sectores.where((sector) {
      final texto = '''
      ${_nombre(sector)}
      ${_descripcion(sector)}
      ${_estado(sector) ? 'activo' : 'inactivo'}
      '''
          .toLowerCase();

      return texto.contains(query);
    }).toList();
  }

  Future<void> cargarSectores() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await sectorService.listarSectores();

      if (!mounted) return;

      setState(() {
        sectores = data;
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

  Future<void> cambiarEstado(Map<String, dynamic> sector) async {
    final idSector = _idSector(sector);
    final activo = _estado(sector);
    final nuevoEstado = !activo;

    if (idSector <= 0) {
      _mensaje('No se encontró el ID del sector.', true);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            activo ? 'Desactivar sector' : 'Activar sector',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            activo
                ? '¿Deseas desactivar este sector?'
                : '¿Deseas activar este sector?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    nuevoEstado ? JassColors.success : JassColors.danger,
                foregroundColor: Colors.white,
              ),
              child: Text(nuevoEstado ? 'Activar' : 'Desactivar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await sectorService.cambiarEstadoSector(
        idSector: idSector,
        estado: nuevoEstado,
      );

      if (!mounted) return;

      _mensaje(
        nuevoEstado
            ? 'Sector activado correctamente.'
            : 'Sector desactivado correctamente.',
        false,
      );

      await cargarSectores();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  void abrirFormulario({Map<String, dynamic>? sector}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.jassSurface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return _SectorFormSheet(
          sector: sector,
          onGuardar: ({
            required String nombre,
            required String descripcion,
            required bool estado,
          }) async {
            if (sector == null) {
              await sectorService.registrarSector(
                nombre: nombre,
                descripcion: descripcion,
                estado: estado,
              );
            } else {
              await sectorService.actualizarSector(
                idSector: _idSector(sector),
                nombre: nombre,
                descripcion: descripcion,
                estado: estado,
              );
            }

            if (!mounted) return;

            Navigator.pop(context);

            _mensaje(
              sector == null
                  ? 'Sector registrado correctamente.'
                  : 'Sector actualizado correctamente.',
              false,
            );

            await cargarSectores();
          },
        );
      },
    );
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

    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/admin-recibos');
    }
  }

  void _volverDashboard() {
    Navigator.pushReplacementNamed(context, '/admin-dashboard');
  }

  void _abrirMenuAdmin() {
    showAdminQuickMenu(
      context: context,
      onRefresh: cargarSectores,
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
          onRefresh: cargarSectores,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(22, 20, 22, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 14),
                _buildSearch(),
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
                    onRetry: cargarSectores,
                  ),
                if (!cargando && error.isEmpty && sectoresFiltrados.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No hay sectores para mostrar.',
                        style: TextStyle(
                          color: context.jassTextMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (!cargando && error.isEmpty)
                  ...sectoresFiltrados.map((sector) {
                    final activo = _estado(sector);

                    return _SectorCard(
                      nombre: _nombre(sector),
                      descripcion: _descripcion(sector),
                      activo: activo,
                      onEditar: () => abrirFormulario(sector: sector),
                      onCambiarEstado: () => cambiarEstado(sector),
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
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: context.jassSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _volverDashboard,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.jassTextPrimary,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registros',
                style: TextStyle(
                  color: secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Sectores',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 25,
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
          ),
          child: IconButton(
            onPressed: cargarSectores,
            icon: Icon(
              Icons.refresh_rounded,
              color: context.jassTextPrimary,
            ),
          ),
        ),
        SizedBox(width: 8),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: () => abrirFormulario(),
            icon: Icon(
              Icons.add_rounded,
              color: context.jassSurface,
            ),
            tooltip: 'Registrar sector',
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
      decoration: InputDecoration(
        hintText: 'Buscar sector...',
        prefixIcon: Icon(Icons.search_rounded),
        filled: true,
        fillColor: context.jassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  final String nombre;
  final String descripcion;
  final bool activo;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;

  _SectorCard({
    required this.nombre,
    required this.descripcion,
    required this.activo,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final Color secondary = JassColors.secondary;
    return Container(
      margin: EdgeInsets.only(bottom: 14),
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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.jassSelectedSurface,
                child: Icon(
                  Icons.map_rounded,
                  color: secondary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  nombre,
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _EstadoChip(activo: activo),
            ],
          ),
          SizedBox(height: 12),
          Text(
            descripcion,
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditar,
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    'Editar',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.jassTextPrimary,
                    side: BorderSide(color: context.jassBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCambiarEstado,
                  icon: Icon(
                    activo
                        ? Icons.block_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text(
                    activo ? 'Desactivar' : 'Activar',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activo
                        ? Color(0xFFFFECEC)
                        : Color(0xFFEAF8EF),
                    foregroundColor: activo
                        ? JassColors.danger
                        : JassColors.success,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectorFormSheet extends StatefulWidget {
  final Map<String, dynamic>? sector;
  final Future<void> Function({
    required String nombre,
    required String descripcion,
    required bool estado,
  }) onGuardar;

  _SectorFormSheet({
    required this.sector,
    required this.onGuardar,
  });

  @override
  State<_SectorFormSheet> createState() => _SectorFormSheetState();
}

class _SectorFormSheetState extends State<_SectorFormSheet> {
  final Color secondary = JassColors.secondary;
  late final TextEditingController nombreController;
  late final TextEditingController descripcionController;

  bool estado = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();

    final sector = widget.sector;

    nombreController = TextEditingController(
      text: sector == null
          ? ''
          : (sector['nombre'] ?? sector['nombreSector'] ?? '').toString(),
    );

    descripcionController = TextEditingController(
      text: sector == null ? '' : (sector['descripcion'] ?? '').toString(),
    );

    if (sector != null) {
      final value = sector['estado'];
      if (value is bool) {
        estado = value;
      } else {
        estado = value.toString().toLowerCase() == 'true' ||
            value.toString().toLowerCase() == 'activo';
      }
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    final nombre = nombreController.text.trim();
    final descripcion = descripcionController.text.trim();

    if (nombre.isEmpty) {
      _mensaje('Ingresa el nombre del sector.', true);
      return;
    }

    if (descripcion.isEmpty) {
      _mensaje('Ingresa una descripción.', true);
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      await widget.onGuardar(
        nombre: nombre,
        descripcion: descripcion,
        estado: estado,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
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

  @override
  Widget build(BuildContext context) {
    final editando = widget.sector != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editando ? 'Editar sector' : 'Registrar sector',
              style: TextStyle(
                color: context.jassTextPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Los sectores se usarán al registrar suministros, generar recibos y consultar lecturas.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            SizedBox(height: 18),
            _Input(
              controller: nombreController,
              label: 'Nombre del sector',
            ),
            _Input(
              controller: descripcionController,
              label: 'Descripción',
              maxLines: 3,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Estado activo',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                estado
                    ? 'El sector estará disponible para nuevos suministros.'
                    : 'El sector no estará disponible para nuevos registros.',
              ),
              value: estado,
              activeThumbColor: secondary,
              onChanged: (value) {
                setState(() {
                  estado = value;
                });
              },
            ),
            SizedBox(height: 18),
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
                  guardando ? 'Guardando...' : 'Guardar sector',
                  style: TextStyle(fontWeight: FontWeight.w900),
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
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  _Input({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: context.jassSurfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final bool activo;

  _EstadoChip({
    required this.activo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: activo ? Color(0xFFEAF8EF) : Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: activo ? JassColors.success : JassColors.danger,
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

