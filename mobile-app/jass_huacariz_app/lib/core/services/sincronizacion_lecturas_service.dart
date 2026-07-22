import '../config/api_config.dart';
import '../database/offline_database.dart';
import '../storage/secure_storage_service.dart';
import 'api_service.dart';
import 'lectura_offline_service.dart';
import 'lecturador_service.dart';

class SincronizacionLecturasService {
  SincronizacionLecturasService({
    OfflineDatabase? database,
    SecureStorageService? storage,
    ApiService? apiService,
    LecturadorService? lecturadorService,
    LecturaOfflineService? offlineService,
  })  : _database = database ?? OfflineDatabase.instance,
        _storage = storage ?? SecureStorageService(),
        _apiService = apiService ?? ApiService(),
        _lecturadorService = lecturadorService ?? LecturadorService(),
        _offlineService = offlineService ?? LecturaOfflineService();

  final OfflineDatabase _database;
  final SecureStorageService _storage;
  final ApiService _apiService;
  final LecturadorService _lecturadorService;
  final LecturaOfflineService _offlineService;

  Future<bool> backendDisponible() async {
    try {
      await _apiService.get(ApiConfig.health, withAuth: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> sincronizarPendientes() async {
    final rol = await _storage.getUserRole();
    if (!_storage.esRolLecturador(rol)) {
      return {
        'conectado': false,
        'sincronizadas': 0,
        'errores': 0,
        'mensaje': 'La sincronización corresponde al lecturador.',
      };
    }

    if (!await backendDisponible()) {
      return {
        'conectado': false,
        'sincronizadas': 0,
        'errores': 0,
        'mensaje': 'Sin conexión con el servidor.',
      };
    }

    await _storage.deactivateOfflineMode();
    await _database.restaurarLecturasInterrumpidas();

    final lectorId = (await _storage.getUserName() ?? '').trim();
    final pendientes = await _database.listarPendientesSincronizacion(
      lectorId: lectorId,
    );

    int sincronizadas = 0;
    int errores = 0;

    for (final lectura in pendientes) {
      final idLocal = lectura['id_local']?.toString() ?? '';
      if (idLocal.isEmpty) continue;
      await _database.marcarSincronizando(idLocal);

      try {
        final tipo = (lectura['tipo_operacion'] ?? 'LECTURA')
            .toString()
            .toUpperCase();
        late final Map<String, dynamic> respuesta;

        if (tipo == 'MANTENIMIENTO') {
          respuesta = await _lecturadorService.registrarMantenimiento(
            codigoSuministro: lectura['codigo_suministro'].toString(),
            anio: _entero(lectura['anio']),
            mes: _entero(lectura['mes']),
            observacion: lectura['observacion']?.toString(),
            idOperacionCliente: idLocal,
          );
        } else {
          respuesta = await _lecturadorService.registrarLectura(
            codigoSuministro: lectura['codigo_suministro'].toString(),
            lecturaActual: _numero(lectura['lectura_actual']),
            anio: _entero(lectura['anio']),
            mes: _entero(lectura['mes']),
            observacion: lectura['observacion']?.toString(),
            idOperacionCliente: idLocal,
          );
        }

        await _database.marcarSincronizada(
          idLocal: idLocal,
          respuestaServidor: respuesta,
        );
        sincronizadas++;
      } catch (e) {
        await _database.marcarError(
          idLocal: idLocal,
          mensaje: e.toString().replaceFirst('Exception: ', ''),
        );
        errores++;
      }
    }

    try {
      await _offlineService.prepararDatosOffline();
    } catch (_) {
      // La sincronización guardada no se invalida si solo falla la actualización del catálogo.
    }

    return {
      'conectado': true,
      'sincronizadas': sincronizadas,
      'errores': errores,
      'pendientesProcesadas': pendientes.length,
      'mensaje': errores == 0
          ? 'Sincronización completada.'
          : 'Se sincronizaron $sincronizadas y quedaron $errores con error.',
    };
  }

  double _numero(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _entero(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
