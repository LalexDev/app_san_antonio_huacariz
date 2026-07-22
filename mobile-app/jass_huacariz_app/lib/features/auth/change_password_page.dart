import 'package:flutter/material.dart';

import '../../shared/theme/jass_colors.dart';
import '../../shared/theme/jass_theme_context.dart';

import '../../core/storage/secure_storage_service.dart';
import '../../shared/widgets/cliente_bottom_nav.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  Color get primary => context.jassTextPrimary;
  static const Color secondary = JassColors.secondary;
  Color get background => context.jassBackground;
  Color get muted => context.jassTextMuted;
  static const Color danger = JassColors.danger;
  static const Color success = JassColors.success;
  static const Color warning = JassColors.warning;

  final TextEditingController actualController = TextEditingController();
  final TextEditingController nuevaController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();

 
  final SecureStorageService storageService = SecureStorageService();

  bool verActual = false;
  bool verNueva = false;
  bool verConfirmar = false;
  bool cargando = false;

  @override
  void dispose() {
    actualController.dispose();
    nuevaController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  void mostrarMensaje(
  String mensaje, {
  Color? color,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensaje),
      backgroundColor:
          color ?? Theme.of(context).colorScheme.primary,
    ),
  );
}


  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Cerrar sesión',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '¿Deseas cerrar tu sesión actual?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: danger,
                foregroundColor: Colors.white,
              ),
              child: Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await storageService.clearSession();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
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

  void _irPagar() {
    Navigator.pushReplacementNamed(context, '/recibos');
  }

  void _volver() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _irPerfil();
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
                          icon: Icons.person_rounded,
                          label: 'Perfil',
                          onTap: () {
                            Navigator.pop(context);
                            _irPerfil();
                          },
                        ),
                        ClienteMenuTile(
                          icon: Icons.logout_rounded,
                          label: 'Salir',
                          onTap: () {
                            Navigator.pop(context);
                            cerrarSesion();
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
        currentIndex: 3,
        onTap: _goBottomCliente,
        onPlus: _abrirMenuCliente,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderTop(),
              SizedBox(height: 18),
              _buildHero(),
              SizedBox(height: 18),
              _buildFormCard(),
              SizedBox(height: 18),
              _buildTipsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTop() {
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
            onPressed: cargando ? null : _volver,
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
                'Cambiar contraseña',
                style: TextStyle(
                  color: primary,
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
          colors: [
            Color(0xFF0F3D57),
            Color(0xFF1DA1C2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: JassColors.primary.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seguridad de cuenta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Actualiza tu contraseña para proteger tu información.',
                  style: TextStyle(
                    color: Color(0xFFE7F8FF),
                    fontSize: 14,
                    height: 1.4,
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

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.jassSurface,
        borderRadius: BorderRadius.circular(26),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actualizar contraseña',
            style: TextStyle(
              color: primary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Ingresa tu contraseña actual y define una nueva clave.',
            style: TextStyle(
              color: muted,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 22),
          _PasswordField(
            label: 'Contraseña actual',
            hint: 'Ingresa tu contraseña actual',
            controller: actualController,
            visible: verActual,
            onToggle: () {
              setState(() {
                verActual = !verActual;
              });
            },
          ),
          SizedBox(height: 16),
          _PasswordField(
            label: 'Nueva contraseña',
            hint: 'Mínimo 6 caracteres',
            controller: nuevaController,
            visible: verNueva,
            onToggle: () {
              setState(() {
                verNueva = !verNueva;
              });
            },
          ),
          SizedBox(height: 16),
          _PasswordField(
            label: 'Confirmar contraseña',
            hint: 'Repite la nueva contraseña',
            controller: confirmarController,
            visible: verConfirmar,
            onToggle: () {
              setState(() {
                verConfirmar = !verConfirmar;
              });
            },
          ),
          SizedBox(height: 24),
          
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.jassSelectedSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFCFEFF7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security_rounded,
                color: secondary,
              ),
              SizedBox(width: 10),
              Text(
                'Recomendaciones',
                style: TextStyle(
                  color: primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _TipItem(text: 'Usa una contraseña de mínimo 6 caracteres.'),
          _TipItem(text: 'No compartas tu clave con otras personas.'),
          _TipItem(text: 'Evita usar tu DNI o fecha de nacimiento como clave.'),
          _TipItem(text: 'Cambia tu contraseña periódicamente.'),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    const Color secondary = JassColors.secondary;
    final Color fieldBackground = context.jassSurfaceAlt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !visible,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            filled: true,
            fillColor: fieldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(
                color: context.jassBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(
                color: context.jassBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(
                color: secondary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = context.jassTextPrimary;
    final Color muted = context.jassTextMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: primary,
            size: 18,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: muted,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
