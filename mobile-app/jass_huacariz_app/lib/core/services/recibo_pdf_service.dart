import 'dart:typed_data';

import '../config/api_config.dart';
import 'api_service.dart';

class ReciboPdfService {
  static final ApiService _api = ApiService();

  static int _id(Map<String, dynamic> recibo) {
    final value = recibo['id'] ?? recibo['idRecibo'] ?? recibo['reciboId'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static Future<Uint8List> generar(Map<String, dynamic> recibo) async {
    final idRecibo = _id(recibo);

    if (idRecibo <= 0) {
      throw Exception('No se encontró un ID válido para generar el PDF.');
    }

    return _api.getBytes(
      ApiConfig.clienteMeReciboPdf(idRecibo),
      accept: 'application/pdf',
    );
  }
}