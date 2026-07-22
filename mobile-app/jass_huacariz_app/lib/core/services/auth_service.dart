import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final SecureStorageService _storage =
      SecureStorageService();

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    return {};
  }

  Future<bool> login({
    required String codigoUsuario,
    required String password,
  }) async {
    final response = _asMap(
      await _apiService.post(
        ApiConfig.login,
        {
          'codigoUsuario': codigoUsuario.trim(),
          'password': password,
        },
        withAuth: false,
      ),
    );

    final token = response['token']?.toString().trim() ?? '';
    final rol = response['rol']?.toString().trim() ?? '';
    final usuario = response['codigoUsuario']
            ?.toString()
            .trim() ??
        codigoUsuario.trim();

    if (token.isEmpty) {
      throw Exception('El backend no devolvió token.');
    }

    if (rol.isEmpty) {
      throw Exception(
        'El backend no devolvió el rol del usuario.',
      );
    }

    if (!_storage.esRolPermitido(rol)) {
      await _storage.clearSession();

      throw Exception(
        'Acceso no permitido. Esta aplicación es '
        'exclusiva para ADMINISTRADOR y LECTURADOR.',
      );
    }

    await _storage.saveAuthenticatedSession(
      token: token,
      rol: rol,
      codigoUsuario: usuario,
    );

    return true;
  }

  Future<bool> loginOfflineLector({
    String? codigoUsuario,
  }) async {
    final disponible =
        await _storage.canUseOfflineLectorSession();

    if (!disponible) {
      throw Exception(
        'No existe una sesión anterior de lecturador '
        'para ingresar sin conexión.',
      );
    }

    final usuarioGuardado =
        (await _storage.getUserName() ?? '').trim();
    final usuarioIngresado =
        (codigoUsuario ?? '').trim();

    if (usuarioIngresado.isNotEmpty &&
        usuarioGuardado.toUpperCase() !=
            usuarioIngresado.toUpperCase()) {
      throw Exception(
        'El usuario ingresado no coincide con el '
        'lecturador guardado en este dispositivo.',
      );
    }

    await _storage.activateOfflineMode();

    return true;
  }

  Future<void> limpiarSesionNoPermitida() async {
    await _storage.clearUnsupportedSession();
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<String?> getRol() async {
    return _storage.getUserRole();
  }

  Future<String?> getCodigoUsuario() async {
    return _storage.getUserName();
  }

  Future<bool> estaAutenticado() async {
    return _storage.hasAllowedSession();
  }

  Future<bool> puedeIngresarOfflineComoLecturador() async {
    return _storage.canUseOfflineLectorSession();
  }

  Future<bool> estaEnModoOffline() async {
    return _storage.isOfflineMode();
  }
}
