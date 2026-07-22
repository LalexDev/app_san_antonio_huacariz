import 'package:uuid/uuid.dart';

import '../database/offline_database.dart';
import '../storage/secure_storage_service.dart';
import 'lecturador_service.dart';
import 'tarifa_service.dart';

class LecturaOfflineService {
  LecturaOfflineService({
    OfflineDatabase? database,
    LecturadorService? lecturadorService,
    TarifaService? tarifaService,
    SecureStorageService? storage,
    Uuid? uuid,
  })  : _database = database ?? OfflineDatabase.instance,
        _lecturadorService = lecturadorService ?? LecturadorService(),
        _tarifaService = tarifaService ?? TarifaService(),
        _storage = storage ?? SecureStorageService(),
        _uuid = uuid ?? const Uuid();

  final OfflineDatabase _database;
  final LecturadorService _lecturadorService;
  final TarifaService _tarifaService;
  final SecureStorageService _storage;
  final Uuid _uuid;

  Future<void> validarLecturador() async {
    final rol = await _storage.getUserRole();
    if (!_storage.esRolLecturador(rol)) {
      throw Exception(
        'El trabajo sin conexión está disponible únicamente para el lecturador.',
      );
    }
  }

  Future<Map<String, dynamic>> prepararDatosOffline() async {
    await validarLecturador();

    final suministros = await _lecturadorService.listarSuministrosOffline();
    final tarifas = await _tarifaService.listarTarifas();
    final configuracion =
        await _tarifaService.obtenerConfiguracionCobranza();

    final guardados = await _database.reemplazarSuministros(suministros);
    await _database.guardarTarifas(tarifas);
    await _database.guardarConfiguracionCobranza(configuracion);

    return {
      'suministros': guardados,
      'tarifas': tarifas.length,
      'fecha': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> buscarSuministro(
    String codigoSuministro,
  ) async {
    await validarLecturador();
    final codigo = _normalizarCodigo(codigoSuministro);
    if (codigo.isEmpty) {
      throw Exception('Ingresa o escanea el código del suministro.');
    }

    final modoOffline = await _storage.isOfflineMode();
    if (!modoOffline) {
      try {
        final remoto = await _lecturadorService.buscarSuministro(codigo);
        await _database.guardarSuministro(remoto);
        return {
          ...remoto,
          'origenOffline': false,
          'estadoConexion': 'EN_LINEA',
        };
      } catch (_) {
        // Continúa con la copia local cuando el servidor no está disponible.
      }
    }

    final local = await _database.buscarSuministroPorCodigo(codigo);
    if (local == null) {
      throw Exception(
        'No hay conexión y el suministro $codigo no está guardado en este celular. '
        'Conéctate una vez y actualiza el catálogo.',
      );
    }

    return {
      ...local,
      'origenOffline': true,
      'estadoConexion': 'SIN_CONEXION',
    };
  }

  Future<Map<String, dynamic>> registrarLecturaLocal({
    required Map<String, dynamic> suministro,
    required double lecturaActual,
    required int anio,
    required int mes,
    String observacion = '',
  }) async {
    return _guardarOperacionLocal(
      suministro: suministro,
      tipoOperacion: 'LECTURA',
      lecturaActual: lecturaActual,
      anio: anio,
      mes: mes,
      observacion: observacion,
    );
  }

  Future<Map<String, dynamic>> registrarMantenimientoLocal({
    required Map<String, dynamic> suministro,
    required int anio,
    required int mes,
    String observacion = '',
  }) async {
    final lecturaAnterior = _numero(
      suministro['lecturaAnterior'] ?? suministro['lecturaInicial'],
    );

    return _guardarOperacionLocal(
      suministro: suministro,
      tipoOperacion: 'MANTENIMIENTO',
      lecturaActual: lecturaAnterior,
      anio: anio,
      mes: mes,
      observacion: observacion.isEmpty
          ? 'Recibo generado por mantenimiento sin conexión.'
          : observacion,
    );
  }

  Future<Map<String, dynamic>> _guardarOperacionLocal({
    required Map<String, dynamic> suministro,
    required String tipoOperacion,
    required double lecturaActual,
    required int anio,
    required int mes,
    required String observacion,
  }) async {
    await validarLecturador();

    final codigo = _normalizarCodigo(
      suministro['codigoSuministro'] ?? suministro['codigo'],
    );
    if (codigo.isEmpty) throw Exception('No se encontró el suministro.');
    if (!_booleano(suministro['estado'], true)) {
      throw Exception('El suministro o cliente se encuentra inactivo.');
    }
    if (mes < 1 || mes > 12 || anio < 2024) {
      throw Exception('El periodo seleccionado no es válido.');
    }

    final esMantenimiento = tipoOperacion == 'MANTENIMIENTO';
    final permite = esMantenimiento
        ? _booleano(suministro['permiteGenerarMantenimiento'])
        : _booleano(suministro['permiteRegistrarLectura']);
    if (!permite) {
      throw Exception(
        _texto(
          suministro['mensajeEstado'],
          'El suministro no permite esta operación.',
        ),
      );
    }

    final lecturaAnterior = _numero(
      suministro['lecturaAnterior'] ?? suministro['lecturaInicial'],
    );
    if (!esMantenimiento && lecturaActual < lecturaAnterior) {
      throw Exception(
        'La lectura actual no puede ser menor a ${lecturaAnterior.toStringAsFixed(3)} m³.',
      );
    }

    final ultimaAnio = _enteroNullable(suministro['anioUltimaLectura']);
    final ultimoMes = _enteroNullable(suministro['mesUltimaLectura']);
    if (ultimaAnio != null && ultimoMes != null) {
      final periodo = anio * 12 + mes;
      final ultimoPeriodo = ultimaAnio * 12 + ultimoMes;
      if (periodo <= ultimoPeriodo) {
        throw Exception(
          'El periodo debe ser posterior a la última lectura registrada.',
        );
      }
    }

    final duplicada = await _database.buscarLecturaPorPeriodo(
      codigoSuministro: codigo,
      anio: anio,
      mes: mes,
    );
    if (duplicada != null) {
      throw Exception('Ya existe una operación local para $mes/$anio.');
    }

    final consumo = esMantenimiento ? 0.0 : lecturaActual - lecturaAnterior;
    final recibo = await calcularReciboEstimado(
      suministro: suministro,
      tipoOperacion: tipoOperacion,
      consumo: consumo,
      anio: anio,
      mes: mes,
    );

    final idLocal = _uuid.v4();
    final lectorId = (await _storage.getUserName() ?? '').trim();
    if (lectorId.isEmpty) throw Exception('No se encontró el lecturador.');

    await _database.insertarLecturaPendiente({
      'idLocal': idLocal,
      'codigoSuministro': codigo,
      'tipoOperacion': tipoOperacion,
      'lecturaAnterior': lecturaAnterior,
      'lecturaActual': lecturaActual,
      'anio': anio,
      'mes': mes,
      'observacion': observacion,
      'fechaRegistroLocal': DateTime.now().toIso8601String(),
      'reciboEstimado': recibo,
      'lectorId': lectorId,
    });

    return {
      ...suministro,
      'idLocal': idLocal,
      'idOperacionCliente': idLocal,
      'codigoSuministro': codigo,
      'tipoOperacion': tipoOperacion,
      'lecturaAnterior': lecturaAnterior,
      'lecturaActual': lecturaActual,
      'consumoM3': consumo,
      'anio': anio,
      'mes': mes,
      'observacion': observacion,
      'fechaLectura': DateTime.now().toIso8601String(),
      'estadoSincronizacion': 'PENDIENTE',
      'origenOffline': true,
      'recibo': recibo,
    };
  }

  Future<Map<String, dynamic>> calcularReciboEstimado({
    required Map<String, dynamic> suministro,
    required String tipoOperacion,
    required double consumo,
    required int anio,
    required int mes,
  }) async {
    final configuracion =
        await _database.obtenerConfiguracionCobranza();
    if (configuracion == null) {
      throw Exception(
        'No existe configuración de cobranza guardada. Actualiza el catálogo con conexión.',
      );
    }

    final esMantenimiento = tipoOperacion == 'MANTENIMIENTO';
    final subtotalAgua = esMantenimiento
        ? 0.0
        : await _calcularAguaPorTramos(consumo);
    final cargoMantenimiento = esMantenimiento
        ? _numero(configuracion['cargo_mantenimiento'])
        : 0.0;
    final cargoLector = esMantenimiento
        ? 0.0
        : _numero(configuracion['cargo_lector']);
    final cargoOtros = esMantenimiento
        ? 0.0
        : _numero(configuracion['cargo_otros']);
    const mora = 0.0;
    final total = subtotalAgua +
        cargoMantenimiento +
        cargoLector +
        cargoOtros +
        mora;

    final dias = _entero(configuracion['dias_vencimiento'], 15);
    final vencimiento = DateTime.now().add(Duration(days: dias));

    return {
      'id': null,
      'codigoRecibo': 'PEND-${DateTime.now().millisecondsSinceEpoch}',
      'codigoSuministro': suministro['codigoSuministro'],
      'direccionSuministro': suministro['direccionSuministro'],
      'aliasSuministro': suministro['aliasSuministro'],
      'sector': suministro['nombreSector'],
      'nombreCliente': suministro['nombreCliente'],
      'dniCliente': suministro['dniCliente'],
      'anio': anio,
      'mes': mes,
      'consumoM3': consumo,
      'subtotalAgua': _redondear2(subtotalAgua),
      'cargoMantenimiento': _redondear2(cargoMantenimiento),
      'cargoLector': _redondear2(cargoLector),
      'cargoOtros': _redondear2(cargoOtros),
      'mora': mora,
      'total': _redondear2(total),
      'estadoRecibo': 'PENDIENTE_SINCRONIZACION',
      'fechaEmision': DateTime.now().toIso8601String(),
      'fechaVencimiento': vencimiento.toIso8601String().split('T').first,
      'montoProvisional': true,
    };
  }

  Future<double> _calcularAguaPorTramos(double consumo) async {
    if (consumo < 1) return 0;
    final tarifas = await _database.listarTarifasActivas();
    if (tarifas.isEmpty) {
      throw Exception(
        'No existen tarifas guardadas. Actualiza el catálogo con conexión.',
      );
    }

    double subtotal = 0;
    double inicioAnterior = 0;
    for (final tarifa in tarifas) {
      final hasta = tarifa['consumo_hasta'] == null
          ? null
          : _numero(tarifa['consumo_hasta']);
      final precio = _numero(tarifa['precio_m3']);
      if (consumo <= inicioAnterior) break;

      final limite = hasta == null
          ? consumo
          : (consumo < hasta ? consumo : hasta);
      final consumoTramo = limite - inicioAnterior;
      if (consumoTramo > 0) subtotal += consumoTramo * precio;
      if (hasta == null || consumo <= hasta) break;
      inicioAnterior = hasta;
    }
    return _redondear2(subtotal);
  }

  Future<List<Map<String, dynamic>>> listarHistorialLocal() async {
    await validarLecturador();
    final lectorId = (await _storage.getUserName() ?? '').trim();
    if (lectorId.isEmpty) return [];

    final filas = await _database.listarLecturasLocales(lectorId: lectorId);
    final resultado = <Map<String, dynamic>>[];

    for (final fila in filas) {
      final estado = _texto(fila['estado_sincronizacion']).toUpperCase();
      // Una vez sincronizada, la versión oficial se obtiene del servidor.
      if (estado == 'SINCRONIZADA') continue;

      final codigo = _texto(fila['codigo_suministro']);
      final suministro =
          await _database.buscarSuministroPorCodigo(codigo) ?? {};
      final recibo = _database.decodificarReciboEstimado(
        fila['recibo_estimado_json'],
      );

      resultado.add({
        ...suministro,
        'idLocal': fila['id_local'],
        'idOperacionCliente': fila['id_local'],
        'codigoSuministro': codigo,
        'tipoOperacion': fila['tipo_operacion'],
        'lecturaAnterior': _numero(fila['lectura_anterior']),
        'lecturaActual': _numero(fila['lectura_actual']),
        'consumoM3': _numero(fila['consumo']),
        'anio': _enteroNullable(fila['anio']),
        'mes': _enteroNullable(fila['mes']),
        'observacion': fila['observacion'],
        'fechaRegistro': fila['fecha_registro_local'],
        'fechaLectura': fila['fecha_registro_local'],
        'estadoSincronizacion': estado,
        'mensajeError': fila['mensaje_error'],
        'intentos': fila['intentos'],
        'origenOffline': true,
        'recibo': recibo,
        'total': recibo?['total'] ?? 0,
        'totalRecibo': recibo?['total'] ?? 0,
        'estadoRecibo': recibo?['estadoRecibo'] ?? estado,
      });
    }
    return resultado;
  }

  Future<int> contarPendientes() async {
    await validarLecturador();
    final lectorId = (await _storage.getUserName() ?? '').trim();
    if (lectorId.isEmpty) return 0;
    return _database.contarPendientes(lectorId: lectorId);
  }

  Future<int> contarSuministrosGuardados() async {
    await validarLecturador();
    return _database.contarSuministros();
  }

  String _normalizarCodigo(dynamic value) {
    return _texto(value).toUpperCase();
  }

  String _texto(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  double _numero(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
        fallback;
  }

  int? _enteroNullable(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  int _entero(dynamic value, int fallback) {
    return _enteroNullable(value) ?? fallback;
  }

  bool _booleano(dynamic value, [bool fallback = false]) {
    if (value is bool) return value;
    if (value == null) return fallback;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'activo';
  }

  double _redondear2(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
