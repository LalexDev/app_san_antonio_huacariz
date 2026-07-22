import '../config/api_config.dart';
import 'api_service.dart';

class LecturadorAdminService {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _asList(dynamic response) {
    if (response is List) {
      return response.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    if (response is Map && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (response is Map && response['content'] is List) {
      return (response['content'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {};
  }

  Future<List<Map<String, dynamic>>> listarLecturadores() async {
    final response = await _api.get(ApiConfig.lecturadores);
    return _asList(response);
  }

  Future<Map<String, dynamic>> obtenerLecturadorPorId(int idLecturador) async {
    final response = await _api.get(
      ApiConfig.lecturadorPorId(idLecturador),
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>> registrarLecturador(
    Map<String, dynamic> data,
  ) async {
    final dni = (data['dni'] ?? '').toString().trim();
    final password = (data['password'] ?? data['contrasena'] ?? '')
        .toString()
        .trim();

    final payload = {
      'dni': dni,
      'codigoUsuario': (data['codigoUsuario'] ?? dni).toString().trim(),
      'nombres': (data['nombres'] ?? '').toString().trim(),
      'apellidos': (data['apellidos'] ?? '').toString().trim(),
      'telefono': (data['telefono'] ?? '').toString().trim(),
      'correo': (data['correo'] ?? '').toString().trim(),
      'password': password,
      'contrasena': password,
      'estado': data['estado'] ?? true,
    };

    final response = await _api.post(ApiConfig.lecturadores, payload);
    return _asMap(response);
  }

  Future<Map<String, dynamic>> actualizarLecturador(
    int idLecturador,
    Map<String, dynamic> data,
  ) async {
    final dni = (data['dni'] ?? '').toString().trim();
    final password = (data['password'] ?? data['contrasena'] ?? '')
        .toString()
        .trim();

    final payload = {
      'dni': dni,
      'codigoUsuario': (data['codigoUsuario'] ?? dni).toString().trim(),
      'nombres': (data['nombres'] ?? '').toString().trim(),
      'apellidos': (data['apellidos'] ?? '').toString().trim(),
      'telefono': (data['telefono'] ?? '').toString().trim(),
      'correo': (data['correo'] ?? '').toString().trim(),
      'estado': data['estado'] ?? true,
    };

    if (password.isNotEmpty) {
      payload['password'] = password;
      payload['contrasena'] = password;
    }

    final response = await _api.put(
      ApiConfig.lecturadorPorId(idLecturador),
      payload,
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>> cambiarEstadoLecturador({
    required int idLecturador,
    required bool estado,
  }) async {
    final response = await _api.patch(
      ApiConfig.cambiarEstadoLecturador(idLecturador, estado),
      {},
    );

    return _asMap(response);
  }
}