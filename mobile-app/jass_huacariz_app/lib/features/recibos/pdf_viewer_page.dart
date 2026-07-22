import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';
import 'package:printing/printing.dart';

import '../../core/services/recibo_pdf_service.dart';
import '../../shared/widgets/cliente_bottom_nav.dart';

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;
  Color get background => context.jassBackground;
  Color get muted => context.jassTextMuted;
  static const Color danger = JassColors.danger;
  static const Color success = JassColors.success;

  Map<String, dynamic> recibo = {};
  Uint8List? pdfBytes;

  bool cargando = true;
  bool generado = false;
  String error = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (generado) return;
    generado = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      recibo = args;
    } else if (args is Map) {
      recibo = Map<String, dynamic>.from(args);
    } else {
      recibo = {};
    }

    _cargarPdfReal();
  }

  String _texto(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  int _id(Map<String, dynamic> recibo) {
    final value = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  String _codigoRecibo() {
    final value =
        recibo['codigoRecibo'] ?? recibo['numeroRecibo'] ?? recibo['codigo'];

    final text = value?.toString().trim() ?? 'recibo';

    if (text.isEmpty) return 'recibo';

    return text.replaceAll('/', '-').replaceAll(' ', '_');
  }

  String _codigoReciboMostrar() {
    return _texto(
      recibo['codigoRecibo'] ??
          recibo['numeroRecibo'] ??
          recibo['codigo'] ??
          'REC-${_id(recibo)}',
      'Recibo',
    );
  }

  String _codigoSuministro() {
    return _texto(
      recibo['codigoSuministro'] ??
          recibo['suministroCodigo'] ??
          recibo['codigoSuministroRecibo'] ??
          recibo['numeroSuministro'] ??
          recibo['suministro'],
      'SIN-SUMINISTRO',
    );
  }

  String _estado() {
    return _texto(
      recibo['estadoRecibo'] ?? recibo['estado'] ?? recibo['situacion'],
      'PENDIENTE',
    ).toUpperCase();
  }

  bool _puedePagar() {
    final estado = _estado();
    return estado == 'PENDIENTE' || estado == 'VENCIDO';
  }

  Future<void> _cargarPdfReal() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final bytes = await ReciboPdfService.generar(recibo);

      if (!mounted) return;

      setState(() {
        pdfBytes = bytes;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar PDF: $error'),
          backgroundColor: danger,
        ),
      );
    }
  }

  Future<void> _compartirPdf() async {
    if (pdfBytes == null) return;

    await Printing.sharePdf(
      bytes: pdfBytes!,
      filename: '${_codigoRecibo()}.pdf',
    );
  }

  Future<void> _imprimirPdf() async {
    if (pdfBytes == null) return;

    await Printing.layoutPdf(
      name: '${_codigoRecibo()}.pdf',
      onLayout: (_) async => pdfBytes!,
    );
  }

  void _irHome() {
    Navigator.pushReplacementNamed(context, '/home');
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

  void _irPagar() {
    if (!_puedePagar()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Este recibo no está pendiente de pago.'),
          backgroundColor: success,
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
      _irRecibos();
    }
  }

  // Barra inferior cliente:
  // 0 = Inicio, 1 = Recibos, 2 = Pagar, 3 = Perfil.
  void _goBottomCliente(int index) {
    if (index == 0) {
      _irHome();
    }

    if (index == 1) {
      _irRecibos();
    }

    if (index == 2) {
      _irPagar();
    }

    if (index == 3) {
      _irPerfil();
    }
  }

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
                            _irPagar();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.refresh_rounded,
                          label: 'Recargar',
                          onTap: () {
                            Navigator.pop(context);
                            _cargarPdfReal();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.print_rounded,
                          label: 'Imprimir',
                          onTap: () {
                            Navigator.pop(context);
                            _imprimirPdf();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.share_rounded,
                          label: 'Compartir',
                          onTap: () {
                            Navigator.pop(context);
                            _compartirPdf();
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: _buildHeader(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: _buildToolbar(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 96),
                child: _buildBody(),
              ),
            ),
          ],
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
                _codigoReciboMostrar(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                _codigoSuministro(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted,
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

  Widget _buildToolbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.jassBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: JassColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: cargando || pdfBytes == null ? null : _compartirPdf,
              icon: Icon(Icons.download_rounded, size: 18),
              label: Text(
                'Descargar',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: secondary.withValues(alpha: 0.45),
                elevation: 0,
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: cargando || pdfBytes == null ? null : _imprimirPdf,
              icon: Icon(Icons.print_rounded, size: 18),
              label: Text(
                'Imprimir',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                backgroundColor: context.jassSurfaceAlt,
                disabledForegroundColor: muted,
                side: BorderSide(
                  color: context.jassBorder,
                ),
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: context.jassSurfaceAlt,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: context.jassBorder,
              ),
            ),
            child: IconButton(
              onPressed: cargando ? null : _cargarPdfReal,
              icon: Icon(
                Icons.refresh_rounded,
                color: primary,
              ),
              tooltip: 'Recargar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (cargando) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: context.jassSurface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: context.jassBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text(
                'Generando PDF del recibo...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (pdfBytes == null) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFECEC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFD1D1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                color: danger,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'No se pudo cargar el PDF del recibo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                error.isEmpty ? 'Verifica la conexión con el backend.' : error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarPdfReal,
                icon: Icon(Icons.refresh_rounded),
                label: Text(
                  'Reintentar',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: context.jassSurface,
          border: Border.all(
            color: context.jassBorder,
          ),
        ),
        child: PdfPreview(
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          pdfFileName: '${_codigoRecibo()}.pdf',
          build: (_) async => pdfBytes!,
        ),
      ),
    );
  }
}
