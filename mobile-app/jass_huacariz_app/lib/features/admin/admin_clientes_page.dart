// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations
import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/cliente_service.dart';
import '../../core/services/sector_service.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminClientesPage extends StatefulWidget {
  const AdminClientesPage({super.key});

  @override
  State<AdminClientesPage> createState() => _AdminClientesPageState();
}

class _AdminClientesPageState extends State<AdminClientesPage> {
  final Color secondary = JassColors.secondary;
  final ClienteService clienteService = ClienteService();
  final SectorService sectorService = SectorService();

  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> sectores = [];

  bool cargando = false;
  String error = '';
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  int _idCliente(Map<String, dynamic> cliente) {
    final value = cliente['id'] ?? cliente['idCliente'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  String _nombreCliente(Map<String, dynamic> cliente) {
    final nombres = _txt(cliente['nombres'], '');
    final apellidos = _txt(cliente['apellidos'], '');
    final nombreCompleto = '$nombres $apellidos'.trim();

    return nombreCompleto.isEmpty ? 'Sin nombre' : nombreCompleto;
  }

  bool _estadoCliente(Map<String, dynamic> cliente) {
    final value = cliente['estado'];

    if (value is bool) return value;

    final text = value.toString().toLowerCase().trim();

    return text == 'true' || text == 'activo' || text == '1';
  }

  List<Map<String, dynamic>> get clientesFiltrados {
    final query = busqueda.trim().toLowerCase();

    if (query.isEmpty) return clientes;

    return clientes.where((cliente) {
      final texto = '''
      ${_nombreCliente(cliente)}
      ${cliente['dni']}
      ${cliente['telefono']}
      ${cliente['correo']}
      ${cliente['suministros']}
      '''
          .toLowerCase();

      return texto.contains(query);
    }).toList();
  }

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final clientesData = await clienteService.listarClientes();
      final sectoresData = await sectorService.listarSectores();

      if (!mounted) return;

      setState(() {
        clientes = clientesData;
        sectores = sectoresData;
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

  void _mensaje(String mensaje, bool esError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor:
            esError ? JassColors.danger : JassColors.success,
      ),
    );
  }

  Future<void> _cambiarEstadoCliente(
    Map<String, dynamic> cliente, {
    bool cerrarDetalle = false,
  }) async {
    final idCliente = _idCliente(cliente);
    final activoActual = _estadoCliente(cliente);
    final nuevoEstado = !activoActual;

    if (idCliente <= 0) {
      _mensaje('No se encontró el ID del cliente.', true);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            activoActual ? 'Desactivar cliente' : 'Activar cliente',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            activoActual
                ? '¿Deseas desactivar este cliente?'
                : '¿Deseas activar este cliente?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: nuevoEstado
                    ? JassColors.success
                    : JassColors.danger,
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
      await clienteService.cambiarEstadoCliente(
        idCliente: idCliente,
        estado: nuevoEstado,
      );

      if (!mounted) return;

      if (cerrarDetalle) {
        Navigator.pop(context);
      }

      _mensaje(
        nuevoEstado
            ? 'Cliente activado correctamente.'
            : 'Cliente desactivado correctamente.',
        false,
      );

      await cargarDatos();
    } catch (e) {
      if (!mounted) return;

      _mensaje(
        e.toString().replaceFirst('Exception: ', ''),
        true,
      );
    }
  }

  void _abrirEditarCliente(Map<String, dynamic> cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.jassSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return _EditarClienteSheet(
          cliente: cliente,
          onGuardar: (payload) async {
            final idCliente = _idCliente(cliente);

            if (idCliente <= 0) {
              throw Exception('No se encontró el ID del cliente.');
            }

            await clienteService.actualizarCliente(
              idCliente,
              payload,
            );

            if (!mounted) return;

            Navigator.pop(context);

            _mensaje('Cliente actualizado correctamente.', false);

            await cargarDatos();
          },
        );
      },
    );
  }

  Future<void> _abrirDetalleCliente(Map<String, dynamic> cliente) async {
    final idCliente = _idCliente(cliente);

    List<Map<String, dynamic>> suministros = [];

    if (cliente['suministros'] is List) {
      suministros = (cliente['suministros'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (suministros.isEmpty && idCliente > 0) {
      try {
        suministros = await clienteService.listarSuministrosPorCliente(
          idCliente,
        );
      } catch (_) {}
    }

    if (!mounted) return;

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
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: EdgeInsets.all(22),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalle del cliente',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _nombreCliente(cliente),
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'DNI: ${_txt(cliente['dni'])}',
                  style: TextStyle(
                    color: context.jassTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 18),
                _DetalleResumenGrid(
                  telefono: _txt(cliente['telefono']),
                  correo: _txt(cliente['correo']),
                  activo: _estadoCliente(cliente),
                  suministros: suministros.length,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _abrirEditarCliente(cliente);
                        },
                        icon: Icon(Icons.edit_outlined),
                        label: Text(
                          'Editar cliente',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.jassTextPrimary,
                          side: BorderSide(
                            color: context.jassBorder,
                          ),
                          backgroundColor: context.jassSelectedSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _cambiarEstadoCliente(
                            cliente,
                            cerrarDetalle: true,
                          );
                        },
                        icon: Icon(
                          _estadoCliente(cliente)
                              ? Icons.block_rounded
                              : Icons.check_circle_outline_rounded,
                        ),
                        label: Text(
                          _estadoCliente(cliente)
                              ? 'Desactivar'
                              : 'Activar',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _estadoCliente(cliente)
                              ? Color(0xFFFFECEC)
                              : Color(0xFFEAF8EF),
                          foregroundColor: _estadoCliente(cliente)
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
                SizedBox(height: 24),
                Text(
                  'Suministros del cliente',
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 14),
                if (suministros.isEmpty)
                  Text(
                    'Este cliente no tiene suministros registrados.',
                    style: TextStyle(
                      color: context.jassTextMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  ...suministros.map((suministro) {
                    final activo = suministro['estado'] == true ||
                        suministro['estado'].toString().toLowerCase() ==
                            'true';

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.jassSurfaceAlt,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: context.jassBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            color: secondary,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _txt(suministro['codigoSuministro']),
                                  style: TextStyle(
                                    color: context.jassTextPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _txt(suministro['aliasSuministro']),
                                  style: TextStyle(
                                    color: context.jassTextPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  _txt(suministro['direccionSuministro']),
                                  style: TextStyle(
                                    color: context.jassTextMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _txt(
                                    suministro['nombreSector'] ??
                                        suministro['sector'],
                                  ),
                                  style: TextStyle(
                                    color: context.jassTextMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _EstadoChip(activo: activo),
                        ],
                      ),
                    );
                  }),
                SizedBox(height: 18),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirFormularioCliente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.jassSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return _RegistrarClienteSheet(
          sectores: sectores,
          onGuardar: (payload) async {
            await clienteService.registrarCliente(payload);

            if (!mounted) return;

            Navigator.pop(context);

            _mensaje('Cliente registrado correctamente.', false);

            await cargarDatos();
          },
        );
      },
    );
  }

  void _go(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    }

    if (index == 1) return;

    if (index == 2) {
      Navigator.pushReplacementNamed(context, '/admin-tarifas');
    }

    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/admin-recibos');
    }
  }

  void _abrirMenuAdmin() {
    showAdminQuickMenu(
      context: context,
      onRefresh: cargarDatos,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.jassBackground,
      extendBody: true,
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 1,
        onTap: _go,
        onPlus: _abrirMenuAdmin,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: cargarDatos,
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
                    onRetry: cargarDatos,
                  ),
                if (!cargando && error.isEmpty && clientesFiltrados.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('No hay clientes para mostrar.'),
                    ),
                  ),
                if (!cargando && error.isEmpty)
                  ...clientesFiltrados.map((cliente) {
                    final suministros = cliente['suministros'];

                    return _ClienteCard(
                      nombre: _nombreCliente(cliente),
                      dni: _txt(cliente['dni']),
                      telefono: _txt(cliente['telefono']),
                      correo: _txt(cliente['correo']),
                      activo: _estadoCliente(cliente),
                      cantidadSuministros:
                          suministros is List ? suministros.length : 0,
                      onDetalle: () => _abrirDetalleCliente(cliente),
                      onEditar: () => _abrirEditarCliente(cliente),
                      onCambiarEstado: () => _cambiarEstadoCliente(cliente),
                    );
                  }),
                SizedBox(height: 90),
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
                'Gestión de clientes',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Clientes',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: secondary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            onPressed: _abrirFormularioCliente,
            tooltip: 'Registrar cliente',
            icon: Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.jassSurface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            onPressed: cargarDatos,
            tooltip: 'Actualizar',
            icon: Icon(
              Icons.refresh_rounded,
              color: context.jassTextPrimary,
            ),
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
        hintText: 'Buscar por DNI, cliente o suministro...',
        prefixIcon: Icon(Icons.search),
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

class _DetalleResumenGrid extends StatelessWidget {
  final String telefono;
  final String correo;
  final bool activo;
  final int suministros;

  _DetalleResumenGrid({
    required this.telefono,
    required this.correo,
    required this.activo,
    required this.suministros,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ResumenBox(
                label: 'Teléfono',
                value: telefono,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _ResumenBox(
                label: 'Correo',
                value: correo,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ResumenBox(
                label: 'Estado cliente',
                value: activo ? 'Activo' : 'Inactivo',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _ResumenBox(
                label: 'Total suministros',
                value: '$suministros',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResumenBox extends StatelessWidget {
  final String label;
  final String value;

  _ResumenBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
  constraints: BoxConstraints(
    minHeight: 74,),
  padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.jassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final String nombre;
  final String dni;
  final String telefono;
  final String correo;
  final bool activo;
  final int cantidadSuministros;
  final VoidCallback onDetalle;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;

  _ClienteCard({
    required this.nombre,
    required this.dni,
    required this.telefono,
    required this.correo,
    required this.activo,
    required this.cantidadSuministros,
    required this.onDetalle,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
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
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C',
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  nombre,
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _EstadoChip(activo: activo),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'DNI: $dni',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tel: $telefono · $correo',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Suministros: $cantidadSuministros',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetalle,
                  icon: Icon(Icons.visibility_outlined, size: 18),
                  label: Text(
                    'Detalle',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.jassTextPrimary,
                    side: BorderSide(color: context.jassTextPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEditar,
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    'Editar',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.jassSelectedSurface,
                    foregroundColor: context.jassTextPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
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

class _RegistrarClienteSheet extends StatefulWidget {
  final List<Map<String, dynamic>> sectores;
  final Future<void> Function(Map<String, dynamic> payload) onGuardar;

  _RegistrarClienteSheet({
    required this.sectores,
    required this.onGuardar,
  });

  @override
  State<_RegistrarClienteSheet> createState() => _RegistrarClienteSheetState();
}

class _RegistrarClienteSheetState extends State<_RegistrarClienteSheet> {
  final Color secondary = JassColors.secondary;
  final dniController = TextEditingController();
  final nombresController = TextEditingController();
  final apellidosController = TextEditingController();
  final telefonoController = TextEditingController();
  final correoController = TextEditingController();

  final direccionController = TextEditingController();
  final referenciaController = TextEditingController();
  final aliasController = TextEditingController();
  final lecturaInicialController = TextEditingController(text: '0');

  int? idSectorSeleccionado;
  final List<Map<String, dynamic>> suministros = [];

  bool guardando = false;

  @override
  void initState() {
    super.initState();

    if (widget.sectores.isNotEmpty) {
      idSectorSeleccionado = _idSector(widget.sectores.first);
    }
  }

  @override
  void dispose() {
    dniController.dispose();
    nombresController.dispose();
    apellidosController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    direccionController.dispose();
    referenciaController.dispose();
    aliasController.dispose();
    lecturaInicialController.dispose();
    super.dispose();
  }

  int _idSector(Map<String, dynamic> sector) {
    final value = sector['id'] ?? sector['idSector'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
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

  void agregarSuministro() {
    final direccion = direccionController.text.trim();
    final referencia = referenciaController.text.trim();
    final alias = aliasController.text.trim();
    final lectura = double.tryParse(lecturaInicialController.text.trim()) ?? 0;

    if (idSectorSeleccionado == null || idSectorSeleccionado == 0) {
      _mensaje('Selecciona un sector.', true);
      return;
    }

    if (direccion.isEmpty || alias.isEmpty) {
      _mensaje('Completa dirección y alias del suministro.', true);
      return;
    }

    setState(() {
      suministros.add({
        'idSector': idSectorSeleccionado,
        'direccionSuministro': direccion,
        'referencia': referencia,
        'aliasSuministro': alias,
        'lecturaInicial': lectura,
        'estado': true,
      });

      direccionController.clear();
      referenciaController.clear();
      aliasController.clear();
      lecturaInicialController.text = '0';
    });
  }

  Future<void> guardarCliente() async {
    final dni = dniController.text.trim();
    final nombres = nombresController.text.trim();
    final apellidos = apellidosController.text.trim();
    final telefono = telefonoController.text.trim();
    final correo = correoController.text.trim();

    if (dni.isEmpty || nombres.isEmpty || apellidos.isEmpty) {
      _mensaje('Completa DNI, nombres y apellidos.', true);
      return;
    }

    if (suministros.isEmpty) {
      _mensaje('Agrega al menos un suministro.', true);
      return;
    }

    final payload = {
      'dni': dni,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'correo': correo,
      'estado': true,
      'suministros': suministros,
    };

    setState(() {
      guardando = true;
    });

    try {
      await widget.onGuardar(payload);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar cliente',
              style: TextStyle(
                color: context.jassTextPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Registra los datos del cliente y uno o más suministros.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 18),
            _Input(
              controller: dniController,
              label: 'DNI',
              keyboardType: TextInputType.number,
            ),
            _Input(
              controller: nombresController,
              label: 'Nombres',
            ),
            _Input(
              controller: apellidosController,
              label: 'Apellidos',
            ),
            _Input(
              controller: telefonoController,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
            ),
            _Input(
              controller: correoController,
              label: 'Correo',
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 12),
            Text(
              'Suministros',
              style: TextStyle(
                color: context.jassTextPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 12),
            _SectorDropdown(
              sectores: widget.sectores,
              value: idSectorSeleccionado,
              onChanged: (value) {
                setState(() {
                  idSectorSeleccionado = value;
                });
              },
            ),
            _Input(
              controller: direccionController,
              label: 'Dirección del suministro',
            ),
            _Input(
              controller: referenciaController,
              label: 'Referencia',
            ),
            _Input(
              controller: aliasController,
              label: 'Alias del suministro',
            ),
            _Input(
              controller: lecturaInicialController,
              label: 'Lectura inicial',
              keyboardType: TextInputType.number,
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: agregarSuministro,
                icon: Icon(Icons.add_location_alt_outlined),
                label: Text('Agregar suministro'),
              ),
            ),
            SizedBox(height: 12),
            if (suministros.isNotEmpty)
              ...suministros.asMap().entries.map((entry) {
                final index = entry.key;
                final suministro = entry.value;

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.jassSurfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.water_drop_rounded,
                        color: secondary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${suministro['aliasSuministro']} · ${suministro['direccionSuministro']}',
                          style: TextStyle(
                            color: context.jassTextPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            suministros.removeAt(index);
                          });
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: JassColors.danger,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: guardando ? null : guardarCliente,
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
                  guardando ? 'Guardando...' : 'Guardar cliente',
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
  }
}

class _EditarClienteSheet extends StatefulWidget {
  final Map<String, dynamic> cliente;
  final Future<void> Function(Map<String, dynamic> payload) onGuardar;

  _EditarClienteSheet({
    required this.cliente,
    required this.onGuardar,
  });

  @override
  State<_EditarClienteSheet> createState() => _EditarClienteSheetState();
}

class _EditarClienteSheetState extends State<_EditarClienteSheet> {
  final Color secondary = JassColors.secondary;
  late final TextEditingController dniController;
  late final TextEditingController nombresController;
  late final TextEditingController apellidosController;
  late final TextEditingController telefonoController;
  late final TextEditingController correoController;

  bool estado = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();

    dniController = TextEditingController(
      text: (widget.cliente['dni'] ?? '').toString(),
    );

    nombresController = TextEditingController(
      text: (widget.cliente['nombres'] ?? '').toString(),
    );

    apellidosController = TextEditingController(
      text: (widget.cliente['apellidos'] ?? '').toString(),
    );

    telefonoController = TextEditingController(
      text: (widget.cliente['telefono'] ?? '').toString(),
    );

    correoController = TextEditingController(
      text: (widget.cliente['correo'] ?? '').toString(),
    );

    final value = widget.cliente['estado'];

    if (value is bool) {
      estado = value;
    } else {
      final text = value.toString().toLowerCase().trim();
      estado = text == 'true' || text == 'activo' || text == '1';
    }
  }

  @override
  void dispose() {
    dniController.dispose();
    nombresController.dispose();
    apellidosController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    final dni = dniController.text.trim();
    final nombres = nombresController.text.trim();
    final apellidos = apellidosController.text.trim();

    if (dni.isEmpty || nombres.isEmpty || apellidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completa DNI, nombres y apellidos.'),
          backgroundColor: JassColors.danger,
        ),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      await widget.onGuardar({
        'dni': dni,
        'nombres': nombres,
        'apellidos': apellidos,
        'telefono': telefonoController.text.trim(),
        'correo': correoController.text.trim(),
        'estado': estado,
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        guardando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: JassColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreCompleto =
        '${nombresController.text} ${apellidosController.text}'.trim();

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
              'Editar cliente',
              style: TextStyle(
                color: context.jassTextPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              nombreCompleto.isEmpty
                  ? 'Actualiza los datos personales y contacto del cliente.'
                  : nombreCompleto,
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 18),
            _Input(
              controller: dniController,
              label: 'DNI',
              keyboardType: TextInputType.number,
            ),
            _Input(
              controller: nombresController,
              label: 'Nombres',
            ),
            _Input(
              controller: apellidosController,
              label: 'Apellidos',
            ),
            _Input(
              controller: telefonoController,
              label: 'Teléfono',
              keyboardType: TextInputType.phone,
            ),
            _Input(
              controller: correoController,
              label: 'Correo',
              keyboardType: TextInputType.emailAddress,
            ),
            DropdownButtonFormField<bool>(
              value: estado,
              decoration: InputDecoration(
                labelText: 'Estado cliente',
                filled: true,
                fillColor: context.jassSurfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: true,
                  child: Text('Activo'),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text('Inactivo'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  estado = value;
                });
              },
            ),
            SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(0xFFFFF3DF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFFD899)),
              ),
              child: Text(
                'El cliente se registra únicamente para la gestión del servicio y sus suministros. No tendrá acceso a esta aplicación.',
                style: TextStyle(
                  color: JassColors.warning,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: guardando ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
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
                      guardando ? 'Guardando...' : 'Guardar',
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
          ],
        ),
      ),
    );
  }
}

class _SectorDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> sectores;
  final int? value;
  final ValueChanged<int?> onChanged;

  _SectorDropdown({
    required this.sectores,
    required this.value,
    required this.onChanged,
  });

  int _idSector(Map<String, dynamic> sector) {
    final value = sector['id'] ?? sector['idSector'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  String _nombreSector(Map<String, dynamic> sector) {
    final value =
        sector['nombreSector'] ?? sector['nombre'] ?? sector['descripcion'];

    if (value == null) return 'Sector';

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (sectores.isEmpty) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(0xFFFFF3DF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Color(0xFFFFD899),
          ),
        ),
        child: Text(
          'No hay sectores cargados. Verifica el endpoint /sectores.',
          style: TextStyle(
            color: JassColors.warning,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(
          labelText: 'Sector',
          filled: true,
          fillColor: context.jassSurfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        items: sectores.map((sector) {
          return DropdownMenuItem<int>(
            value: _idSector(sector),
            child: Text(_nombreSector(sector)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  _Input({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
