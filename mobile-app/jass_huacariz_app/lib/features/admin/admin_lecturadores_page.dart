// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations
import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/services/lecturador_admin_service.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminLecturadoresPage extends StatefulWidget {
  const AdminLecturadoresPage({super.key});

  @override
  State<AdminLecturadoresPage> createState() => _AdminLecturadoresPageState();
}

class _AdminLecturadoresPageState extends State<AdminLecturadoresPage> {
  final Color secondary = JassColors.secondary;
  final LecturadorAdminService lecturadorService = LecturadorAdminService();

  List<Map<String, dynamic>> lecturadores = [];
  bool cargando = false;
  String error = '';
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarLecturadores();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  int _idLecturador(Map<String, dynamic> lecturador) {
    final value = lecturador['id'] ??
        lecturador['idUsuario'] ??
        lecturador['idLecturador'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  String _nombreCompleto(Map<String, dynamic> lecturador) {
    final nombres = _txt(lecturador['nombres'], '');
    final apellidos = _txt(lecturador['apellidos'], '');

    final completo = '$nombres $apellidos'.trim();

    return completo.isEmpty ? 'Lecturador sin nombre' : completo;
  }

  bool _estado(Map<String, dynamic> lecturador) {
    final value = lecturador['estado'];

    if (value is bool) return value;

    final text = value.toString().toLowerCase().trim();

    return text == 'true' || text == 'activo' || text == '1';
  }

  List<Map<String, dynamic>> get lecturadoresFiltrados {
    final query = busqueda.trim().toLowerCase();

    if (query.isEmpty) return lecturadores;

    return lecturadores.where((lecturador) {
      final texto = '''
      ${_nombreCompleto(lecturador)}
      ${lecturador['dni']}
      ${lecturador['codigoUsuario']}
      ${lecturador['telefono']}
      ${lecturador['correo']}
      ${_estado(lecturador) ? 'activo' : 'inactivo'}
      '''
          .toLowerCase();

      return texto.contains(query);
    }).toList();
  }

  Future<void> cargarLecturadores() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final data = await lecturadorService.listarLecturadores();

      if (!mounted) return;

      setState(() {
        lecturadores = data;
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

  Future<void> cambiarEstado(Map<String, dynamic> lecturador) async {
    final id = _idLecturador(lecturador);
    final activoActual = _estado(lecturador);
    final nuevoEstado = !activoActual;

    if (id <= 0) {
      _mensaje('No se encontró el ID del lecturador.', true);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            activoActual ? 'Desactivar lecturador' : 'Activar lecturador',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            activoActual
                ? '¿Deseas desactivar este lecturador?'
                : '¿Deseas activar este lecturador?',
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
      await lecturadorService.cambiarEstadoLecturador(
        idLecturador: id,
        estado: nuevoEstado,
      );

      if (!mounted) return;

      _mensaje(
        nuevoEstado
            ? 'Lecturador activado correctamente.'
            : 'Lecturador desactivado correctamente.',
        false,
      );

      await cargarLecturadores();
    } catch (e) {
      if (!mounted) return;

      _mensaje(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  void abrirFormulario({Map<String, dynamic>? lecturador}) {
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
        return _LecturadorFormSheet(
          lecturador: lecturador,
          onGuardar: (payload) async {
            if (lecturador == null) {
              await lecturadorService.registrarLecturador(payload);
            } else {
              final id = _idLecturador(lecturador);

              if (id <= 0) {
                throw Exception('No se encontró el ID del lecturador.');
              }

              await lecturadorService.actualizarLecturador(
                id,
                payload,
              );
            }

            if (!mounted) return;

            Navigator.pop(context);

            _mensaje(
              lecturador == null
                  ? 'Lecturador registrado correctamente.'
                  : 'Lecturador actualizado correctamente.',
              false,
            );

            await cargarLecturadores();
          },
        );
      },
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
      onRefresh: cargarLecturadores,
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
          onRefresh: cargarLecturadores,
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
                  _ErrorBox(
                    error: error,
                    onRetry: cargarLecturadores,
                  ),
                if (!cargando &&
                    error.isEmpty &&
                    lecturadoresFiltrados.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No hay lecturadores para mostrar.',
                        style: TextStyle(
                          color: context.jassTextMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (!cargando && error.isEmpty)
                  ...lecturadoresFiltrados.map((lecturador) {
                    return _LecturadorCard(
                      nombre: _nombreCompleto(lecturador),
                      dni: _txt(lecturador['dni']),
                      usuario: _txt(
                        lecturador['codigoUsuario'] ?? lecturador['usuario'],
                      ),
                      telefono: _txt(lecturador['telefono']),
                      correo: _txt(lecturador['correo']),
                      activo: _estado(lecturador),
                      onEditar: () => abrirFormulario(lecturador: lecturador),
                      onEstado: () => cambiarEstado(lecturador),
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
          ),
          child: IconButton(
            onPressed: _volverDashboard,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.jassTextPrimary,
            ),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administración',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Lecturadores',
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
            onPressed: cargarLecturadores,
            icon: Icon(
              Icons.refresh_rounded,
              color: context.jassTextPrimary,
            ),
            tooltip: 'Actualizar',
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
              Icons.person_add_alt_1_rounded,
              color: context.jassSurface,
            ),
            tooltip: 'Registrar lecturador',
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
        hintText: 'Buscar por DNI, nombre o usuario...',
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

class _LecturadorCard extends StatelessWidget {
  final String nombre;
  final String dni;
  final String usuario;
  final String telefono;
  final String correo;
  final bool activo;
  final VoidCallback onEditar;
  final VoidCallback onEstado;

  _LecturadorCard({
    required this.nombre,
    required this.dni,
    required this.usuario,
    required this.telefono,
    required this.correo,
    required this.activo,
    required this.onEditar,
    required this.onEstado,
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
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'L',
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
            'DNI: $dni · Usuario: $usuario',
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
          SizedBox(height: 12),
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
                  onPressed: onEstado,
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

class _LecturadorFormSheet extends StatefulWidget {
  final Map<String, dynamic>? lecturador;
  final Future<void> Function(Map<String, dynamic> payload) onGuardar;

  _LecturadorFormSheet({
    required this.lecturador,
    required this.onGuardar,
  });

  @override
  State<_LecturadorFormSheet> createState() => _LecturadorFormSheetState();
}

class _LecturadorFormSheetState extends State<_LecturadorFormSheet> {
  final Color secondary = JassColors.secondary;
  late final TextEditingController dniController;
  late final TextEditingController codigoController;
  late final TextEditingController nombresController;
  late final TextEditingController apellidosController;
  late final TextEditingController telefonoController;
  late final TextEditingController correoController;
  late final TextEditingController passwordController;

  bool estado = true;
  bool guardando = false;

  bool get editando => widget.lecturador != null;

  @override
  void initState() {
    super.initState();

    final data = widget.lecturador;

    dniController = TextEditingController(
      text: data == null ? '' : (data['dni'] ?? '').toString(),
    );

    codigoController = TextEditingController(
      text: data == null
          ? ''
          : (data['codigoUsuario'] ?? data['usuario'] ?? '').toString(),
    );

    nombresController = TextEditingController(
      text: data == null ? '' : (data['nombres'] ?? '').toString(),
    );

    apellidosController = TextEditingController(
      text: data == null ? '' : (data['apellidos'] ?? '').toString(),
    );

    telefonoController = TextEditingController(
      text: data == null ? '' : (data['telefono'] ?? '').toString(),
    );

    correoController = TextEditingController(
      text: data == null ? '' : (data['correo'] ?? '').toString(),
    );

    passwordController = TextEditingController();

    if (data != null) {
      final value = data['estado'];

      if (value is bool) {
        estado = value;
      } else {
        final text = value.toString().toLowerCase().trim();
        estado = text == 'true' || text == 'activo' || text == '1';
      }
    }
  }

  @override
  void dispose() {
    dniController.dispose();
    codigoController.dispose();
    nombresController.dispose();
    apellidosController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    final dni = dniController.text.trim();
    final codigo = codigoController.text.trim().isEmpty
        ? dni
        : codigoController.text.trim();
    final nombres = nombresController.text.trim();
    final apellidos = apellidosController.text.trim();
    final password = passwordController.text.trim();

    if (dni.isEmpty || nombres.isEmpty || apellidos.isEmpty) {
      _mensaje('Completa DNI, nombres y apellidos.', true);
      return;
    }

    if (!editando && password.isEmpty) {
      _mensaje('Ingresa una contraseña para el lecturador.', true);
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      await widget.onGuardar({
        'dni': dni,
        'codigoUsuario': codigo,
        'nombres': nombres,
        'apellidos': apellidos,
        'telefono': telefonoController.text.trim(),
        'correo': correoController.text.trim(),
        'password': password,
        'contrasena': password,
        'estado': estado,
      });
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
              editando ? 'Editar lecturador' : 'Crear lecturador',
              style: TextStyle(
                color: context.jassTextPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Este usuario tendrá acceso al módulo lecturador para buscar suministros, escanear QR y registrar lecturas.',
              style: TextStyle(
                color: context.jassTextMuted,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            SizedBox(height: 18),
            _Input(
              controller: dniController,
              label: 'DNI',
              keyboardType: TextInputType.number,
            ),
            _Input(
              controller: codigoController,
              label: 'Usuario de acceso',
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
            _Input(
              controller: passwordController,
              label: editando
                  ? 'Nueva contraseña (opcional)'
                  : 'Contraseña',
              obscureText: true,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Acceso activo',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                estado
                    ? 'El lecturador podrá iniciar sesión.'
                    : 'El lecturador no podrá acceder al sistema.',
              ),
              value: estado,
              activeColor: secondary,
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
                  guardando
                      ? 'Guardando...'
                      : editando
                          ? 'Guardar cambios'
                          : 'Crear lecturador',
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
  final TextInputType? keyboardType;
  final bool obscureText;

  _Input({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
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

class _ErrorBox extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  _ErrorBox({
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
