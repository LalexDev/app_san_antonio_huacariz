import '../config/api_config.dart';
import 'api_service.dart';

class CanalPagoService {
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

  Future<List<Map<String, dynamic>>> listarActivos() async {
    final response = await _api.get(ApiConfig.canalesPagoActivos);
    return _asList(response);
  }
}