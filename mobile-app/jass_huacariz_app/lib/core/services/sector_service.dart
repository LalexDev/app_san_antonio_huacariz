import '../config/api_config.dart';
import 'api_service.dart';

class SectorService {
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

  Future<List<Map<String, dynamic>>> listarSectores() async {
    final response = await _api.get(ApiConfig.sectores);
    return _asList(response);
  }

  Future<Map<String, dynamic>> registrarSector({
    required String nombre,
    required String descripcion,
    bool estado = true,
  }) async {
    final payload = {
      'nombre': nombre.trim().toUpperCase(),
      'descripcion': descripcion.trim(),
      'estado': estado,
    };

    final response = await _api.post(ApiConfig.sectores, payload);
    return _asMap(response);
  }

  Future<Map<String, dynamic>> actualizarSector({
    required int idSector,
    required String nombre,
    required String descripcion,
    required bool estado,
  }) async {
    final payload = {
      'nombre': nombre.trim().toUpperCase(),
      'descripcion': descripcion.trim(),
      'estado': estado,
    };

    final response = await _api.put('${ApiConfig.sectores}/$idSector', payload);
    return _asMap(response);
  }

  Future<Map<String, dynamic>> cambiarEstadoSector({
    required int idSector,
    required bool estado,
  }) async {
    final response = await _api.patch(
      '${ApiConfig.sectores}/$idSector/estado?estado=$estado',
      {},
    );

    return _asMap(response);
  }
}