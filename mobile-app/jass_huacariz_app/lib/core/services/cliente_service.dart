import '../config/api_config.dart';
import 'api_service.dart';

class ClienteService {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _asList(dynamic response) {
    if (response is List) {
      return response
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
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
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    return {};
  }

  Future<List<Map<String, dynamic>>> listarClientes() async {
    final response = await _api.get(ApiConfig.clientes);
    return _asList(response);
  }

  Future<Map<String, dynamic>> registrarCliente(
    Map<String, dynamic> data,
  ) async {
    final payload = {
      'dni': (data['dni'] ?? '').toString().trim(),
      'nombres': (data['nombres'] ?? '').toString().trim(),
      'apellidos': (data['apellidos'] ?? '').toString().trim(),
      'telefono': (data['telefono'] ?? '').toString().trim(),
      'correo': (data['correo'] ?? '').toString().trim(),
      'estado': data['estado'] ?? true,
      'suministros': data['suministros'] ?? [],
    };

    final response = await _api.post(ApiConfig.clientes, payload);
    return _asMap(response);
  }

  Future<Map<String, dynamic>> actualizarCliente(
    int idCliente,
    Map<String, dynamic> data,
  ) async {
    final payload = {
      'dni': (data['dni'] ?? '').toString().trim(),
      'nombres': (data['nombres'] ?? '').toString().trim(),
      'apellidos': (data['apellidos'] ?? '').toString().trim(),
      'telefono': (data['telefono'] ?? '').toString().trim(),
      'correo': (data['correo'] ?? '').toString().trim(),
      'estado': data['estado'] ?? true,
    };

    final response = await _api.put(
      ApiConfig.clientePorId(idCliente),
      payload,
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>> obtenerClientePorId(int idCliente) async {
    final response = await _api.get(ApiConfig.clientePorId(idCliente));
    return _asMap(response);
  }

  Future<List<Map<String, dynamic>>> listarSuministrosPorCliente(
    int idCliente,
  ) async {
    final response = await _api.get(
      ApiConfig.suministrosPorCliente(idCliente),
    );

    return _asList(response);
  }

  Future<Map<String, dynamic>> cambiarEstadoCliente({
    required int idCliente,
    required bool estado,
  }) async {
    final response = await _api.patch(
      ApiConfig.cambiarEstadoCliente(idCliente, estado),
      {},
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>> cambiarEstadoSuministro({
    required int idCliente,
    required int idSuministro,
    required bool estado,
  }) async {
    final response = await _api.patch(
      ApiConfig.cambiarEstadoSuministro(
        idCliente: idCliente,
        idSuministro: idSuministro,
        estado: estado,
      ),
      {},
    );

    return _asMap(response);
  }
}