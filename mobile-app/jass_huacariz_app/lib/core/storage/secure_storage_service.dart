import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String _tokenKey = 'token';
  static const String _roleKey = 'rol';
  static const String _userKey = 'codigoUsuario';
  static const String _lastOnlineLoginKey =
      'ultimoLoginOnline';
  static const String _offlineLectorEnabledKey =
      'offlineLectorHabilitado';
  static const String _offlineModeKey =
      'modoOfflineActivo';

  String normalizarRol(String? rol) {
    return (rol ?? '').trim().toUpperCase();
  }

  bool esRolAdmin(String? rol) {
    final normalizado = normalizarRol(rol);

    return normalizado == 'ADMIN' ||
        normalizado == 'ROLE_ADMIN';
  }

  bool esRolLecturador(String? rol) {
    final normalizado = normalizarRol(rol);

    return normalizado == 'LECTURADOR' ||
        normalizado == 'ROLE_LECTURADOR' ||
        normalizado == 'LECTOR' ||
        normalizado == 'ROLE_LECTOR';
  }

  bool esRolPermitido(String? rol) {
    return esRolAdmin(rol) || esRolLecturador(rol);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveUserRole(String rol) async {
    await _storage.write(
      key: _roleKey,
      value: normalizarRol(rol),
    );
  }

  Future<String?> getUserRole() async {
    return _storage.read(key: _roleKey);
  }

  Future<void> saveUserName(
    String codigoUsuario,
  ) async {
    await _storage.write(
      key: _userKey,
      value: codigoUsuario.trim(),
    );
  }

  Future<String?> getUserName() async {
    return _storage.read(key: _userKey);
  }

  Future<void> saveAuthenticatedSession({
    required String token,
    required String rol,
    required String codigoUsuario,
  }) async {
    final rolNormalizado = normalizarRol(rol);

    if (!esRolPermitido(rolNormalizado)) {
      await clearSession();

      throw Exception(
        'Solo se permiten sesiones de ADMINISTRADOR '
        'y LECTURADOR.',
      );
    }

    await Future.wait([
      saveToken(token),
      saveUserRole(rolNormalizado),
      saveUserName(codigoUsuario),
      _storage.write(
        key: _lastOnlineLoginKey,
        value: DateTime.now().toIso8601String(),
      ),
      _storage.write(
        key: _offlineLectorEnabledKey,
        value: esRolLecturador(rolNormalizado)
            ? 'true'
            : 'false',
      ),
      _storage.write(
        key: _offlineModeKey,
        value: 'false',
      ),
    ]);
  }

  Future<DateTime?> getLastOnlineLogin() async {
    final value = await _storage.read(
      key: _lastOnlineLoginKey,
    );

    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  Future<bool> canUseOfflineLectorSession() async {
    final token = await getToken();
    final rol = await getUserRole();
    final usuario = await getUserName();
    final enabled = await _storage.read(
      key: _offlineLectorEnabledKey,
    );

    return token != null &&
        token.isNotEmpty &&
        usuario != null &&
        usuario.trim().isNotEmpty &&
        esRolLecturador(rol) &&
        enabled == 'true';
  }

  Future<void> activateOfflineMode() async {
    if (!await canUseOfflineLectorSession()) {
      throw Exception(
        'No existe una sesión previa de lecturador '
        'habilitada para trabajar sin conexión.',
      );
    }

    await _storage.write(
      key: _offlineModeKey,
      value: 'true',
    );
  }

  Future<void> deactivateOfflineMode() async {
    await _storage.write(
      key: _offlineModeKey,
      value: 'false',
    );
  }

  Future<bool> isOfflineMode() async {
    final value = await _storage.read(
      key: _offlineModeKey,
    );

    return value == 'true';
  }

  Future<bool> hasSession() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  Future<bool> hasAllowedSession() async {
    final token = await getToken();
    final rol = await getUserRole();

    return token != null &&
        token.isNotEmpty &&
        esRolPermitido(rol);
  }

  Future<void> clearUnsupportedSession() async {
    final rol = await getUserRole();

    if (rol != null &&
        rol.trim().isNotEmpty &&
        !esRolPermitido(rol)) {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
