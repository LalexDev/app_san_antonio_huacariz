import '../config/api_config.dart';
import 'api_service.dart';

class TarifaService {
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

  // =========================================================
  // TARIFAS POR TRAMOS
  // =========================================================

  Future<List<Map<String, dynamic>>> listarTarifas() async {
    final response = await _api.get(
      ApiConfig.tarifas,
    );

    return _asList(response);
  }

  Future<Map<String, dynamic>> registrarTarifa(
    Map<String, dynamic> data,
  ) async {
    final payload = {
      'nombreTarifa':
          (data['nombreTarifa'] ?? '').toString().trim(),
      'consumoDesde': data['consumoDesde'],
      'consumoHasta': data['consumoHasta'],
      'precioM3': data['precioM3'],
      'estado': data['estado'] ?? true,
    };

    final response = await _api.post(
      ApiConfig.tarifas,
      payload,
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>> actualizarTarifa({
    required int idTarifa,
    required Map<String, dynamic> data,
  }) async {
    final payload = {
      'nombreTarifa':
          (data['nombreTarifa'] ?? '').toString().trim(),
      'consumoDesde': data['consumoDesde'],
      'consumoHasta': data['consumoHasta'],
      'precioM3': data['precioM3'],
      'estado': data['estado'] ?? true,
    };

    try {
      final response = await _api.put(
        ApiConfig.tarifaPorId(idTarifa),
        payload,
      );

      return _asMap(response);
    } catch (_) {
      final response = await _api.patch(
        ApiConfig.tarifaPorId(idTarifa),
        payload,
      );

      return _asMap(response);
    }
  }

  Future<Map<String, dynamic>> cambiarEstadoTarifa({
    required int idTarifa,
    required bool estado,
  }) async {
    final response = await _api.patch(
      ApiConfig.cambiarEstadoTarifa(
        idTarifa,
        estado,
      ),
      {},
    );

    return _asMap(response);
  }

  // Utilízalo solo si TarifaController tiene @DeleteMapping("/{id}").
  Future<void> eliminarTarifa({
    required int idTarifa,
  }) async {
    await _api.delete(
      ApiConfig.tarifaPorId(idTarifa),
    );
  }

  // =========================================================
  // CONFIGURACIÓN GENERAL DE COBRANZA
  // =========================================================

  Future<Map<String, dynamic>>
      obtenerConfiguracionCobranza() async {
    final response = await _api.get(
      ApiConfig.configuracionCobranza,
    );

    return _asMap(response);
  }

  Future<Map<String, dynamic>>
      actualizarConfiguracionCobranza({
    required double cargoLector,
    required double cargoMantenimiento,
    required double cargoOtros,
    required int diasVencimiento,
    required double moraBase,
  }) async {
    final payload = {
      'cargoLector': cargoLector,
      'cargoMantenimiento': cargoMantenimiento,
      'cargoOtros': cargoOtros,
      'diasVencimiento': diasVencimiento,
      'moraBase': moraBase,
    };

    final response = await _api.put(
      ApiConfig.configuracionCobranza,
      payload,
    );

    return _asMap(response);
  }
}