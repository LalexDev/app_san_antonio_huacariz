import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../shared/theme/jass_colors.dart';

class QrScannerPage extends StatefulWidget {
  final bool modoAdmin;

  const QrScannerPage({
    super.key,
    this.modoAdmin = false,
  });

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController scannerController =
      MobileScannerController();

  bool procesado = false;

  String normalizarCodigoQr(String valor) {
    final texto = valor.trim();

    if (texto.isEmpty) return '';

    try {
      final uri = Uri.parse(texto);

      if (uri.hasScheme && uri.host.isNotEmpty) {
        final codigoParam = uri.queryParameters['codigo'];

        if (codigoParam != null &&
            codigoParam.trim().isNotEmpty) {
          return codigoParam.trim().toUpperCase();
        }

        if (uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.last.trim().toUpperCase();
        }
      }
    } catch (_) {
      // Si no es una URL válida, se utiliza el contenido completo.
    }

    return texto.toUpperCase();
  }

  void procesarQr(String raw) {
    if (procesado) return;

    final codigo = normalizarCodigoQr(raw);

    if (codigo.isEmpty) return;

    setState(() {
      procesado = true;
    });

    if (widget.modoAdmin) {
      // El administrador continúa dentro del flujo administrativo.
      Navigator.pushReplacementNamed(
        context,
        '/admin-buscar-suministro',
        arguments: codigo,
      );
    } else {
      // El lecturador devuelve el código a BuscarSuministroPage.
      Navigator.pop(context, codigo);
    }
  }

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      widget.modoAdmin
          ? '/admin-dashboard'
          : '/lector-home',
    );
  }

  void _reiniciarEscaner() {
    setState(() {
      procesado = false;
    });
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JassColors.primary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: JassColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _volver,
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          tooltip: 'Volver',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.modoAdmin
                  ? 'Administrador'
                  : 'Lecturador',
              style: const TextStyle(
                color: Color(0xFFCDEDF5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Escanear QR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await scannerController.toggleTorch();
            },
            icon: const Icon(
              Icons.flash_on_rounded,
            ),
            tooltip: 'Linterna',
          ),
          IconButton(
            onPressed: () async {
              await scannerController.switchCamera();
            },
            icon: const Icon(
              Icons.cameraswitch_rounded,
            ),
            tooltip: 'Cambiar cámara',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;

              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;

              if (raw == null) return;

              procesarQr(raw);
            },
          ),

          // Oscurece ligeramente el entorno para resaltar el área de lectura.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: JassColors.secondary,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Stack(
                children: const [
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _CornerIndicator(
                      alignment: Alignment.topLeft,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _CornerIndicator(
                      alignment: Alignment.topRight,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: _CornerIndicator(
                      alignment: Alignment.bottomLeft,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _CornerIndicator(
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 38,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xD9000000),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: JassColors.secondary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Apunta la cámara al QR del suministro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.modoAdmin
                        ? 'El suministro se abrirá dentro del panel administrativo.'
                        : 'El código será enviado a la búsqueda del lecturador.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFD6E8EE),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (procesado) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _reiniciarEscaner,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Escanear nuevamente',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.38);

    final scanArea = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          size.width / 2,
          size.height / 2,
        ),
        width: 270,
        height: 270,
      ),
      const Radius.circular(30),
    );

    final fullPath = Path()
      ..addRect(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    final scanPath = Path()
      ..addRRect(scanArea);

    final overlayPath = Path.combine(
      PathOperation.difference,
      fullPath,
      scanPath,
    );

    canvas.drawPath(
      overlayPath,
      backgroundPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

class _CornerIndicator extends StatelessWidget {
  final Alignment alignment;

  const _CornerIndicator({
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y < 0
                ? const BorderSide(
                    color: Colors.white,
                    width: 3,
                  )
                : BorderSide.none,
            bottom: alignment.y > 0
                ? const BorderSide(
                    color: Colors.white,
                    width: 3,
                  )
                : BorderSide.none,
            left: alignment.x < 0
                ? const BorderSide(
                    color: Colors.white,
                    width: 3,
                  )
                : BorderSide.none,
            right: alignment.x > 0
                ? const BorderSide(
                    color: Colors.white,
                    width: 3,
                  )
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}