import '../config/api_config.dart';
import 'api_service.dart';

class ClientePortalService {
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

  Future<Map<String, dynamic>> obtenerMiPerfil() async {
    return _asMap(await _api.get(ApiConfig.clienteMe));
  }

  Future<List<Map<String, dynamic>>> listarMisSuministros() async {
    return _asList(await _api.get(ApiConfig.clienteMeSuministros));
  }

  Future<List<Map<String, dynamic>>> listarMisRecibos() async {
    return _asList(await _api.get(ApiConfig.clienteMeRecibos));
  }

  Future<Map<String, dynamic>> cambiarMiPassword({
    required String passwordActual,
    required String nuevaPassword,
    required String confirmarPassword,
  }) async {
    final response = await _api.patch(
      ApiConfig.clienteMePassword,
      {
        'passwordActual': passwordActual,
        'nuevaPassword': nuevaPassword,
        'confirmarPassword': confirmarPassword,
      },
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
    required String confirmarPassword,
  }) {
    return cambiarMiPassword(
      passwordActual: passwordActual,
      nuevaPassword: nuevaPassword,
      confirmarPassword: confirmarPassword,
    );
  }

  Future<Map<String, dynamic>> pagarMiRecibo({
    required int idRecibo,
    required String metodoPago,
    required String codigoOperacion,
    required String comprobantePath,
  }) async {
    final response = await _api.patchMultipart(
      ApiConfig.clienteMePagarRecibo(idRecibo),
      fields: {
        'metodoPago': metodoPago,
        'codigoOperacion': codigoOperacion,
      },
      fileField: 'comprobante',
      filePath: comprobantePath,
    );

    return _asMap(response);
  }
}