import '../config/api_config.dart';
import 'api_service.dart';

class LecturadorService {
  final ApiService _api = ApiService();

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return {};
  }

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

  Future<Map<String, dynamic>> buscarSuministro(
    String codigoSuministro,
  ) async {
    final codigo = codigoSuministro.trim().toUpperCase();
    final response = await _api.get(
      ApiConfig.buscarSuministroLecturador(codigo),
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> buscarPorCodigo(
    String codigoSuministro,
  ) {
    return buscarSuministro(codigoSuministro);
  }

  Future<Map<String, dynamic>> buscarSuministroPorCodigo(
    String codigoSuministro,
  ) {
    return buscarSuministro(codigoSuministro);
  }

  Future<List<Map<String, dynamic>>> listarSuministrosOffline() async {
    final response = await _api.get(
      ApiConfig.suministrosOfflineLecturador,
    );
    return _asList(response);
  }

  Future<Map<String, dynamic>> registrarLectura({
    required String codigoSuministro,
    required double lecturaActual,
    required int anio,
    required int mes,
    String? observacion,
    String? idOperacionCliente,
  }) async {
    final response = await _api.post(
      ApiConfig.registrarLectura,
      {
        'codigoSuministro': codigoSuministro.trim().toUpperCase(),
        'lecturaActual': lecturaActual,
        'anio': anio,
        'mes': mes,
        'observacion': observacion?.trim() ?? '',
        if (idOperacionCliente != null &&
            idOperacionCliente.trim().isNotEmpty)
          'idOperacionCliente': idOperacionCliente.trim(),
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> registrarMantenimiento({
    required String codigoSuministro,
    required int anio,
    required int mes,
    String? observacion,
    String? idOperacionCliente,
  }) async {
    final response = await _api.post(
      ApiConfig.registrarMantenimiento,
      {
        'codigoSuministro': codigoSuministro.trim().toUpperCase(),
        'anio': anio,
        'mes': mes,
        'observacion': observacion?.trim() ?? '',
        if (idOperacionCliente != null &&
            idOperacionCliente.trim().isNotEmpty)
          'idOperacionCliente': idOperacionCliente.trim(),
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> registrarLecturaPayload(
    Map<String, dynamic> data,
  ) {
    return registrarLectura(
      codigoSuministro: (data['codigoSuministro'] ?? '').toString(),
      lecturaActual: _numero(data['lecturaActual']),
      anio: _entero(data['anio'], DateTime.now().year),
      mes: _entero(data['mes'], DateTime.now().month),
      observacion: data['observacion']?.toString(),
      idOperacionCliente: data['idOperacionCliente']?.toString(),
    );
  }

  Future<List<Map<String, dynamic>>> listarHistorial() async {
    final response = await _api.get(ApiConfig.historialLecturas);
    return _asList(response);
  }

  double _numero(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  int _entero(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
