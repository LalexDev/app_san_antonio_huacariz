import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';

class ApiService {
  final SecureStorageService _storage = SecureStorageService();

  static const Duration _timeout = Duration(seconds: 20);

  Uri _uri(String endpoint) {
    return Uri.parse('${ApiConfig.baseUrl}$endpoint');
  }

  Future<Map<String, String>> _headers({
    bool withAuth = true,
    String accept = 'application/json',
    String contentType = 'application/json',
  }) async {
    final headers = {
      'Content-Type': contentType,
      'Accept': accept,
    };

    if (withAuth) {
      final token = await _storage.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool withAuth = true}) async {
    try {
      final response = await http
          .get(
            _uri(endpoint),
            headers: await _headers(withAuth: withAuth),
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Uint8List> getBytes(
    String endpoint, {
    bool withAuth = true,
    String accept = 'application/pdf',
  }) async {
    try {
      final response = await http
          .get(
            _uri(endpoint),
            headers: await _headers(
              withAuth: withAuth,
              accept: accept,
            ),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }

      final bodyText = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );

      if (bodyText.trim().isNotEmpty) {
        final mensaje = _extraerMensajeError(bodyText);

        if (mensaje.isNotEmpty) {
          throw Exception(mensaje);
        }
      }

      throw Exception('Error HTTP ${response.statusCode}');
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            _uri(endpoint),
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    try {
      final response = await http
          .put(
            _uri(endpoint),
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    try {
      final response = await http
          .patch(
            _uri(endpoint),
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }


  Future<dynamic> patchMultipart(
    String endpoint, {
    required Map<String, String> fields,
    required String fileField,
    required String filePath,
    bool withAuth = true,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PATCH',
        _uri(endpoint),
      );

      request.fields.addAll(fields);
      request.files.add(
        await http.MultipartFile.fromPath(
          fileField,
          filePath,
        ),
      );

      if (withAuth) {
        final token = await _storage.getToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      request.headers['Accept'] = 'application/json';

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica tu conexión e inténtalo nuevamente.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    try {
      final response = await http
          .delete(
            _uri(endpoint),
            headers: await _headers(withAuth: withAuth),
          )
          .timeout(_timeout);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que el backend esté encendido.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) {
        return null;
      }

      throw Exception('Error HTTP $statusCode');
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } catch (_) {
      if (statusCode >= 200 && statusCode < 300) {
        return body;
      }

      throw Exception('Error HTTP $statusCode');
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    if (decoded is Map && decoded['mensaje'] != null) {
      throw Exception(decoded['mensaje']);
    }

    if (decoded is Map && decoded['message'] != null) {
      throw Exception(decoded['message']);
    }

    if (decoded is Map && decoded['error'] != null) {
      throw Exception(decoded['error']);
    }

    throw Exception('Error HTTP $statusCode');
  }

  String _extraerMensajeError(String bodyText) {
    try {
      final decoded = jsonDecode(bodyText);

      if (decoded is Map && decoded['mensaje'] != null) {
        return decoded['mensaje'].toString();
      }

      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }

      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}

    return '';
  }
}