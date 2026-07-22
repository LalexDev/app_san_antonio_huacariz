// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_const_declarations
import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config/api_config.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/admin_bottom_nav.dart';

class AdminQrSuministroPage extends StatefulWidget {
  const AdminQrSuministroPage({super.key});

  @override
  State<AdminQrSuministroPage> createState() => _AdminQrSuministroPageState();
}

class _AdminQrSuministroPageState extends State<AdminQrSuministroPage> {
  final Color secondary = JassColors.secondary;
  final ApiService apiService = ApiService();

  final codigoController = TextEditingController();
  final aliasController = TextEditingController();
  final clienteController = TextEditingController();
  final dniController = TextEditingController();
  final direccionController = TextEditingController();
  final sectorController = TextEditingController();

  bool buscando = false;
  bool qrGenerado = false;
  String error = '';
  String qrData = '';

  @override
  void dispose() {
    codigoController.dispose();
    aliasController.dispose();
    clienteController.dispose();
    dniController.dispose();
    direccionController.dispose();
    sectorController.dispose();
    super.dispose();
  }

  String _txt(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  String _codigo(Map<String, dynamic> data) {
    return _txt(
      data['codigoSuministro'] ??
          data['suministroCodigo'] ??
          data['codigo'] ??
          data['numeroSuministro'],
      '',
    );
  }

  String _alias(Map<String, dynamic> data) {
    return _txt(
      data['aliasSuministro'] ??
          data['alias'] ??
          data['referenciaRapida'],
      '',
    );
  }

  String _cliente(Map<String, dynamic> data) {
    return _txt(
      data['titular'] ??
          data['cliente'] ??
          data['nombreCliente'] ??
          data['nombres'] ??
          data['usuario'],
      '',
    );
  }

  String _dni(Map<String, dynamic> data) {
    return _txt(
      data['dniCliente'] ??
          data['dni'] ??
          data['documentoCliente'],
      '',
    );
  }

  String _direccion(Map<String, dynamic> data) {
    return _txt(
      data['direccionSuministro'] ??
          data['direccion'] ??
          data['direccionCliente'],
      '',
    );
  }

  String _sector(Map<String, dynamic> data) {
    return _txt(
      data['nombreSector'] ??
          data['sector'] ??
          data['sectorNombre'],
      '',
    );
  }

  Future<void> buscarSuministro() async {
    final codigo = codigoController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      _mensaje('Ingresa el código del suministro.', true);
      return;
    }

    setState(() {
      buscando = true;
      error = '';
      qrGenerado = false;
    });

    try {
      final response = await apiService.get(
        ApiConfig.buscarSuministroLecturador(codigo),
      );

      Map<String, dynamic> data = {};

      if (response is Map<String, dynamic>) {
        data = response;
      } else if (response is Map) {
        data = Map<String, dynamic>.from(response);
      }

      if (!mounted) return;

      if (data.isEmpty) {
        setState(() {
          buscando = false;
          error = 'No se encontró información del suministro.';
        });
        return;
      }

      codigoController.text = _codigo(data).isEmpty ? codigo : _codigo(data);
      aliasController.text = _alias(data);
      clienteController.text = _cliente(data);
      dniController.text = _dni(data);
      direccionController.text = _direccion(data);
      sectorController.text = _sector(data);

      setState(() {
        buscando = false;
      });

      generarQr();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        buscando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void generarQr() {
    final codigo = codigoController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      _mensaje('Ingresa el código del suministro para generar el QR.', true);
      return;
    }

    codigoController.text = codigo;

    setState(() {
      qrData = codigo;
      qrGenerado = true;
      error = '';
    });
  }

  Future<void> copiarCodigo() async {
    final codigo = codigoController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      _mensaje('No hay código para copiar.', true);
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: codigo),
    );

    _mensaje('Código copiado correctamente.', false);
  }

  void limpiar() {
    codigoController.clear();
    aliasController.clear();
    clienteController.clear();
    dniController.clear();
    direccionController.clear();
    sectorController.clear();

    setState(() {
      qrGenerado = false;
      qrData = '';
      error = '';
    });
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

  void _volverDashboard() {
    Navigator.pushReplacementNamed(context, '/admin-dashboard');
  }

  // Barra inferior del administrador:
  // 0 = Inicio, 1 = Clientes, 2 = Tarifas, 3 = Recibos.
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

  void _abrirMenuAdmin() {
    showAdminQuickMenu(
      context: context,
      onRefresh: () {
        final codigo = codigoController.text.trim();

        if (codigo.isEmpty) {
          _mensaje(
            'Ingresa un código de suministro para actualizar la búsqueda.',
            true,
          );
          return;
        }

        buscarSuministro();
      },
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
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, 20, 22, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 18),
              _buildStats(),
              SizedBox(height: 18),
              _buildInstructions(),
              SizedBox(height: 18),
              _buildContent(),
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
                'Generador QR',
                style: TextStyle(
                  color: secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'QR Suministro',
                style: TextStyle(
                  color: context.jassTextPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Genera la ficha QR para identificar un punto de agua.',
                style: TextStyle(
                  color: context.jassTextMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        _TopCard(
          icon: Icons.qr_code_2_rounded,
          title: 'Estado',
          value: qrGenerado ? 'Generado' : 'Pendiente',
          subtitle: 'Resultado actual',
          selected: true,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TopCard(
                icon: Icons.water_drop_rounded,
                title: 'Código suministro',
                value: codigoController.text.trim().isEmpty
                    ? '-'
                    : codigoController.text.trim().toUpperCase(),
                subtitle: 'Código único',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _TopCard(
                icon: Icons.person_rounded,
                title: 'Cliente',
                value: clienteController.text.trim().isEmpty
                    ? '-'
                    : clienteController.text.trim(),
                subtitle: 'Responsable',
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        _TopCard(
          icon: Icons.home_rounded,
          title: 'Alias',
          value: aliasController.text.trim().isEmpty
              ? '-'
              : aliasController.text.trim(),
          subtitle: 'Referencia rápida',
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipTitle(text: 'Identificación rápida'),
          SizedBox(height: 12),
          Text(
            'Ficha QR del suministro',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Este código permite que el lecturador identifique el suministro y registre la lectura desde la app móvil.',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StepBox(
                  number: '1',
                  title: 'Ingresa el código',
                  subtitle: 'Busca el suministro registrado.',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StepBox(
                  number: '2',
                  title: 'Genera el QR',
                  subtitle: 'El QR contendrá el código real.',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StepBox(
                  number: '3',
                  title: 'Imprime y pega',
                  subtitle: 'Colócalo cerca del medidor.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildForm(),
        SizedBox(height: 18),
        _buildQrPreview(),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipTitle(text: 'Datos del suministro'),
          SizedBox(height: 12),
          Text(
            'Información para generar QR',
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Completa o busca los datos que aparecerán en la ficha del suministro.',
            style: TextStyle(
              color: context.jassTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),
          _Input(
            controller: codigoController,
            label: 'Código de suministro',
            hint: 'Ejemplo: SUM-C6DAD1A0',
            icon: Icons.qr_code_rounded,
            onSubmitted: (_) => buscarSuministro(),
          ),
          _Input(
            controller: aliasController,
            label: 'Alias del suministro',
            hint: 'Ejemplo: Casa principal',
            icon: Icons.home_outlined,
          ),
          _Input(
            controller: clienteController,
            label: 'Cliente',
            hint: 'Ejemplo: Juan Pérez',
            icon: Icons.person_outline_rounded,
          ),
          _Input(
            controller: dniController,
            label: 'DNI',
            hint: 'Ejemplo: 12345678',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
          _Input(
            controller: direccionController,
            label: 'Dirección del suministro',
            hint: 'Ejemplo: Av. Principal 123',
            icon: Icons.location_on_outlined,
          ),
          _Input(
            controller: sectorController,
            label: 'Sector',
            hint: 'Ejemplo: ZONA PRINCIPAL DE HUACARIZ',
            icon: Icons.map_outlined,
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFFFFF3DF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFFFD899)),
            ),
            child: Text(
              'Recomendación: el QR debe contener el código del suministro. Los demás datos ayudan a identificar la ficha impresa.',
              style: TextStyle(
                color: JassColors.warning,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
          if (error.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                error,
                style: TextStyle(
                  color: JassColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: buscando ? null : copiarCodigo,
                  icon: Icon(Icons.copy_rounded),
                  label: Text(
                    'Copiar',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: buscando ? null : limpiar,
                  icon: Icon(Icons.cleaning_services_rounded),
                  label: Text(
                    'Limpiar',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: buscando ? null : buscarSuministro,
              icon: buscando
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.search_rounded),
              label: Text(
                buscando ? 'Buscando...' : 'Buscar y generar QR',
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
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: buscando ? null : generarQr,
              icon: Icon(Icons.qr_code_2_rounded),
              label: Text(
                'Generar QR solo con código',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.jassTextPrimary,
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
    );
  }

  Widget _buildQrPreview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.jassBorder),
      ),
      child: qrGenerado
          ? Column(
              children: [
                Container(
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: context.jassBorder),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 210,
                    backgroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'QR generado',
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  qrData,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  clienteController.text.trim().isEmpty
                      ? 'Este QR contiene el código del suministro.'
                      : '${clienteController.text.trim()} · ${aliasController.text.trim()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.jassTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: context.jassSelectedSurface,
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    color: secondary,
                    size: 36,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'QR pendiente',
                  style: TextStyle(
                    color: context.jassTextPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Ingresa el código del suministro para generar la ficha QR.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.jassTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Ejemplo: SUM-C6DAD1A0',
                  style: TextStyle(
                    color: secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
    );
  }
}

class _TopCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool selected;

  _TopCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? JassColors.primary : context.jassSurface;
    final text = selected ? Colors.white : context.jassTextPrimary;
    final sub = selected ? Color(0xFFE7F8FF) : context.jassTextMuted;

    return Container(
      constraints: BoxConstraints(
        minHeight: 96,
      ),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.jassBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                selected ? Colors.white24 : context.jassSelectedSurface,
            child: Icon(
              icon,
              color: selected ? Colors.white : JassColors.secondary,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sub,
                    fontSize: 11,
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
}

class _ChipTitle extends StatelessWidget {
  final String text;

  _ChipTitle({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 7,
      ),
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

class _StepBox extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  _StepBox({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 118,
      ),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.jassSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.jassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: JassColors.secondary,
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: context.jassTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: context.jassTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final Function(String)? onSubmitted;

  _Input({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: context.jassSurfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
