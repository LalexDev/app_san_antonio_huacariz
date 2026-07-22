import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class OfflineDatabase {
  OfflineDatabase._();

  static final OfflineDatabase instance = OfflineDatabase._();

  static const String _databaseName = 'jass_huacariz_offline.db';
  static const int _databaseVersion = 2;

  static const String tablaSuministros = 'suministros_cache';
  static const String tablaLecturas = 'lecturas_pendientes';
  static const String tablaTarifas = 'tarifas_cache';
  static const String tablaConfiguracion = 'configuracion_cobranza_cache';

  Database? _database;

  Future<Database> get database async {
    final actual = _database;
    if (actual != null && actual.isOpen) return actual;
    _database = await _abrirBaseDatos();
    return _database!;
  }

  Future<Database> _abrirBaseDatos() async {
    final path = join(await getDatabasesPath(), _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _crearTablas,
      onUpgrade: _actualizarBaseDatos,
    );
  }

  Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablaSuministros (
        codigo_suministro TEXT PRIMARY KEY,
        id_servidor INTEGER,
        nombre_cliente TEXT,
        dni_cliente TEXT,
        nombre_sector TEXT,
        direccion_suministro TEXT,
        referencia TEXT,
        alias_suministro TEXT,
        lectura_inicial REAL NOT NULL DEFAULT 0,
        lectura_anterior REAL NOT NULL DEFAULT 0,
        anio_ultima_lectura INTEGER,
        mes_ultima_lectura INTEGER,
        estado INTEGER NOT NULL DEFAULT 1,
        estado_instalacion TEXT,
        permite_registrar_lectura INTEGER NOT NULL DEFAULT 0,
        permite_generar_mantenimiento INTEGER NOT NULL DEFAULT 0,
        mensaje_estado TEXT,
        fecha_actualizacion TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablaLecturas (
        id_local TEXT PRIMARY KEY,
        codigo_suministro TEXT NOT NULL,
        tipo_operacion TEXT NOT NULL DEFAULT 'LECTURA',
        lectura_anterior REAL NOT NULL,
        lectura_actual REAL NOT NULL,
        consumo REAL NOT NULL,
        anio INTEGER NOT NULL,
        mes INTEGER NOT NULL,
        observacion TEXT,
        fecha_registro_local TEXT NOT NULL,
        fecha_sincronizacion TEXT,
        estado_sincronizacion TEXT NOT NULL DEFAULT 'PENDIENTE',
        intentos INTEGER NOT NULL DEFAULT 0,
        mensaje_error TEXT,
        respuesta_servidor TEXT,
        recibo_estimado_json TEXT,
        lector_id TEXT NOT NULL,
        FOREIGN KEY (codigo_suministro)
          REFERENCES $tablaSuministros(codigo_suministro)
          ON UPDATE CASCADE
          ON DELETE RESTRICT,
        UNIQUE (codigo_suministro, anio, mes)
      )
    ''');

    await _crearTablasCache(db);
    await _crearIndices(db);
  }

  Future<void> _crearTablasCache(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablaTarifas (
        id_servidor INTEGER PRIMARY KEY,
        nombre_tarifa TEXT,
        consumo_desde REAL NOT NULL DEFAULT 0,
        consumo_hasta REAL,
        precio_m3 REAL NOT NULL DEFAULT 0,
        estado INTEGER NOT NULL DEFAULT 1,
        fecha_actualizacion TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablaConfiguracion (
        id INTEGER PRIMARY KEY,
        cargo_lector REAL NOT NULL DEFAULT 0,
        cargo_mantenimiento REAL NOT NULL DEFAULT 0,
        cargo_otros REAL NOT NULL DEFAULT 0,
        dias_vencimiento INTEGER NOT NULL DEFAULT 15,
        mora_base REAL NOT NULL DEFAULT 0,
        fecha_actualizacion TEXT NOT NULL
      )
    ''');
  }

  Future<void> _crearIndices(DatabaseExecutor db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_lecturas_estado
      ON $tablaLecturas(estado_sincronizacion)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_lecturas_codigo
      ON $tablaLecturas(codigo_suministro)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_lecturas_lector
      ON $tablaLecturas(lector_id)
    ''');
  }

  Future<void> _actualizarBaseDatos(
    Database db,
    int versionAnterior,
    int versionNueva,
  ) async {
    if (versionAnterior < 2) {
      await _agregarColumnaSiFalta(
        db,
        tablaLecturas,
        'tipo_operacion',
        "TEXT NOT NULL DEFAULT 'LECTURA'",
      );
      await _agregarColumnaSiFalta(
        db,
        tablaLecturas,
        'recibo_estimado_json',
        'TEXT',
      );
      await _crearTablasCache(db);
      await _crearIndices(db);
    }
  }

  Future<void> _agregarColumnaSiFalta(
    Database db,
    String tabla,
    String columna,
    String definicion,
  ) async {
    final columnas = await db.rawQuery('PRAGMA table_info($tabla)');
    final existe = columnas.any(
      (item) => item['name']?.toString() == columna,
    );
    if (!existe) {
      await db.execute('ALTER TABLE $tabla ADD COLUMN $columna $definicion');
    }
  }

  String _texto(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  double _numero(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
        fallback;
  }

  int? _enteroNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  bool _booleano(dynamic value, [bool fallback = false]) {
    if (value is bool) return value;
    if (value == null) return fallback;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' ||
        text == '1' ||
        text == 'activo' ||
        text == 'activa' ||
        text == 'instalado';
  }

  int _boolToInt(bool value) => value ? 1 : 0;

  bool intToBool(dynamic value) {
    return value == 1 || value == true || value?.toString() == '1';
  }

  String normalizarCodigo(dynamic value) {
    return _texto(value).toUpperCase();
  }

  Map<String, dynamic> _suministroServidorALocal(
    Map<String, dynamic> suministro,
  ) {
    final codigo = normalizarCodigo(
      suministro['codigoSuministro'] ??
          suministro['suministroCodigo'] ??
          suministro['codigo'] ??
          suministro['numeroSuministro'],
    );

    return {
      'codigo_suministro': codigo,
      'id_servidor': _enteroNullable(
        suministro['id'] ?? suministro['idSuministro'],
      ),
      'nombre_cliente': _texto(
        suministro['nombreCliente'] ??
            suministro['titular'] ??
            suministro['cliente'],
        'No disponible',
      ),
      'dni_cliente': _texto(
        suministro['dniCliente'] ?? suministro['dni'],
        '-',
      ),
      'nombre_sector': _texto(
        suministro['nombreSector'] ??
            suministro['sector'] ??
            suministro['sectorNombre'],
        '-',
      ),
      'direccion_suministro': _texto(
        suministro['direccionSuministro'] ?? suministro['direccion'],
        '-',
      ),
      'referencia': _texto(suministro['referencia'], '-'),
      'alias_suministro': _texto(
        suministro['aliasSuministro'] ?? suministro['alias'],
        '-',
      ),
      'lectura_inicial': _numero(suministro['lecturaInicial']),
      'lectura_anterior': _numero(
        suministro['lecturaAnterior'] ??
            suministro['ultimaLectura'] ??
            suministro['lecturaActual'] ??
            suministro['lecturaInicial'],
      ),
      'anio_ultima_lectura': _enteroNullable(
        suministro['anioUltimaLectura'] ?? suministro['anio'],
      ),
      'mes_ultima_lectura': _enteroNullable(
        suministro['mesUltimaLectura'] ?? suministro['mes'],
      ),
      'estado': _boolToInt(
        _booleano(suministro['estado'] ?? suministro['activo'], true),
      ),
      'estado_instalacion': _texto(
        suministro['estadoInstalacion'],
        'PENDIENTE_INSTALACION',
      ).toUpperCase(),
      'permite_registrar_lectura': _boolToInt(
        _booleano(suministro['permiteRegistrarLectura']),
      ),
      'permite_generar_mantenimiento': _boolToInt(
        _booleano(suministro['permiteGenerarMantenimiento']),
      ),
      'mensaje_estado': _texto(suministro['mensajeEstado']),
      'fecha_actualizacion': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> suministroLocalAFlutter(
    Map<String, dynamic> local,
  ) {
    return {
      'id': local['id_servidor'],
      'codigoSuministro': local['codigo_suministro'],
      'nombreCliente': local['nombre_cliente'],
      'dniCliente': local['dni_cliente'],
      'nombreSector': local['nombre_sector'],
      'direccionSuministro': local['direccion_suministro'],
      'referencia': local['referencia'],
      'aliasSuministro': local['alias_suministro'],
      'lecturaInicial': _numero(local['lectura_inicial']),
      'lecturaAnterior': _numero(local['lectura_anterior']),
      'anioUltimaLectura': local['anio_ultima_lectura'],
      'mesUltimaLectura': local['mes_ultima_lectura'],
      'estado': intToBool(local['estado']),
      'estadoInstalacion': local['estado_instalacion'],
      'permiteRegistrarLectura':
          intToBool(local['permite_registrar_lectura']),
      'permiteGenerarMantenimiento':
          intToBool(local['permite_generar_mantenimiento']),
      'mensajeEstado': local['mensaje_estado'],
      'fechaActualizacionLocal': local['fecha_actualizacion'],
      'origenOffline': true,
    };
  }

  Future<void> _upsertSuministro(
    DatabaseExecutor executor,
    Map<String, dynamic> data,
  ) async {
    final codigo = data['codigo_suministro'].toString();
    final actualizados = await executor.update(
      tablaSuministros,
      data,
      where: 'codigo_suministro = ?',
      whereArgs: [codigo],
    );

    if (actualizados == 0) {
      await executor.insert(
        tablaSuministros,
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> guardarSuministro(
    Map<String, dynamic> suministro,
  ) async {
    final db = await database;
    final data = _suministroServidorALocal(suministro);
    final codigo = data['codigo_suministro'].toString();
    if (codigo.isEmpty) throw Exception('El suministro no tiene código.');
    await _upsertSuministro(db, data);
  }

  Future<int> reemplazarSuministros(
    List<Map<String, dynamic>> suministros,
  ) async {
    final db = await database;

    return db.transaction<int>((transaction) async {
      int guardados = 0;
      for (final suministro in suministros) {
        final data = _suministroServidorALocal(suministro);
        if (data['codigo_suministro'].toString().isEmpty) continue;
        await _upsertSuministro(transaction, data);
        guardados++;
      }
      return guardados;
    });
  }

  Future<Map<String, dynamic>?> buscarSuministroPorCodigo(
    String codigo,
  ) async {
    final db = await database;
    final resultados = await db.query(
      tablaSuministros,
      where: 'codigo_suministro = ?',
      whereArgs: [normalizarCodigo(codigo)],
      limit: 1,
    );
    if (resultados.isEmpty) return null;
    return suministroLocalAFlutter(resultados.first);
  }

  Future<int> contarSuministros() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $tablaSuministros',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> guardarTarifas(
    List<Map<String, dynamic>> tarifas,
  ) async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(tablaTarifas);
      int indice = 1;
      for (final tarifa in tarifas) {
        final id = _enteroNullable(tarifa['id'] ?? tarifa['idTarifa']) ??
            indice++;
        await transaction.insert(
          tablaTarifas,
          {
            'id_servidor': id,
            'nombre_tarifa': _texto(
              tarifa['nombreTarifa'] ?? tarifa['nombre'],
            ),
            'consumo_desde': _numero(
              tarifa['consumoDesde'] ?? tarifa['desde'],
            ),
            'consumo_hasta': tarifa['consumoHasta'] == null
                ? null
                : _numero(tarifa['consumoHasta'] ?? tarifa['hasta']),
            'precio_m3': _numero(
              tarifa['precioM3'] ?? tarifa['precio'],
            ),
            'estado': _boolToInt(
              _booleano(tarifa['estado'], true),
            ),
            'fecha_actualizacion': DateTime.now().toIso8601String(),
          },
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> listarTarifasActivas() async {
    final db = await database;
    final rows = await db.query(
      tablaTarifas,
      where: 'estado = 1',
      orderBy: 'consumo_desde ASC',
    );
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> guardarConfiguracionCobranza(
    Map<String, dynamic> configuracion,
  ) async {
    final db = await database;
    await db.insert(
      tablaConfiguracion,
      {
        'id': 1,
        'cargo_lector': _numero(configuracion['cargoLector']),
        'cargo_mantenimiento':
            _numero(configuracion['cargoMantenimiento']),
        'cargo_otros': _numero(
          configuracion['cargoOtros'] ?? configuracion['otrosCargos'],
        ),
        'dias_vencimiento':
            _enteroNullable(configuracion['diasVencimiento']) ?? 15,
        'mora_base': _numero(configuracion['moraBase']),
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> obtenerConfiguracionCobranza() async {
    final db = await database;
    final rows = await db.query(tablaConfiguracion, where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> insertarLecturaPendiente(
    Map<String, dynamic> lectura,
  ) async {
    final db = await database;
    final codigo = normalizarCodigo(
      lectura['codigoSuministro'] ?? lectura['codigo_suministro'],
    );
    final idLocal = _texto(lectura['idLocal'] ?? lectura['id_local']);
    final anio = _enteroNullable(lectura['anio']);
    final mes = _enteroNullable(lectura['mes']);
    final lectorId = _texto(lectura['lectorId'] ?? lectura['lector_id']);

    if (codigo.isEmpty) throw Exception('No se encontró el suministro.');
    if (idLocal.isEmpty) throw Exception('La operación local no tiene ID.');
    if (anio == null || mes == null) throw Exception('Periodo inválido.');
    if (lectorId.isEmpty) throw Exception('No se encontró el lecturador.');

    final lecturaAnterior = _numero(
      lectura['lecturaAnterior'] ?? lectura['lectura_anterior'],
    );
    final lecturaActual = _numero(
      lectura['lecturaActual'] ?? lectura['lectura_actual'],
    );
    final consumo = lecturaActual - lecturaAnterior;
    final tipo = _texto(lectura['tipoOperacion'], 'LECTURA').toUpperCase();
    final reciboEstimado = lectura['reciboEstimado'];

    await db.transaction<void>((transaction) async {
      final suministroExiste = await transaction.query(
        tablaSuministros,
        columns: ['codigo_suministro'],
        where: 'codigo_suministro = ?',
        whereArgs: [codigo],
        limit: 1,
      );
      if (suministroExiste.isEmpty) {
        throw Exception(
          'El suministro $codigo no está guardado en el celular.',
        );
      }

      await transaction.insert(
        tablaLecturas,
        {
          'id_local': idLocal,
          'codigo_suministro': codigo,
          'tipo_operacion': tipo,
          'lectura_anterior': lecturaAnterior,
          'lectura_actual': lecturaActual,
          'consumo': consumo < 0 ? 0 : consumo,
          'anio': anio,
          'mes': mes,
          'observacion': _texto(lectura['observacion']),
          'fecha_registro_local': _texto(
            lectura['fechaRegistroLocal'],
            DateTime.now().toIso8601String(),
          ),
          'fecha_sincronizacion': null,
          'estado_sincronizacion': 'PENDIENTE',
          'intentos': 0,
          'mensaje_error': null,
          'respuesta_servidor': null,
          'recibo_estimado_json':
              reciboEstimado == null ? null : jsonEncode(reciboEstimado),
          'lector_id': lectorId,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await transaction.update(
        tablaSuministros,
        {
          'lectura_anterior': lecturaActual,
          'anio_ultima_lectura': anio,
          'mes_ultima_lectura': mes,
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        },
        where: 'codigo_suministro = ?',
        whereArgs: [codigo],
      );
    });
  }

  Future<Map<String, dynamic>?> buscarLecturaPorPeriodo({
    required String codigoSuministro,
    required int anio,
    required int mes,
  }) async {
    final db = await database;
    final rows = await db.query(
      tablaLecturas,
      where: 'codigo_suministro = ? AND anio = ? AND mes = ?',
      whereArgs: [normalizarCodigo(codigoSuministro), anio, mes],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<List<Map<String, dynamic>>> listarLecturasLocales({
    required String lectorId,
  }) async {
    final db = await database;
    final rows = await db.query(
      tablaLecturas,
      where: 'lector_id = ?',
      whereArgs: [lectorId],
      orderBy: 'anio DESC, mes DESC, fecha_registro_local DESC',
    );
    return rows.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<List<Map<String, dynamic>>> listarPendientesSincronizacion({
    required String lectorId,
  }) async {
    final db = await database;
    final rows = await db.query(
      tablaLecturas,
      where: "lector_id = ? AND estado_sincronizacion IN ('PENDIENTE','ERROR')",
      whereArgs: [lectorId],
      orderBy: 'fecha_registro_local ASC',
    );
    return rows.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<int> contarPendientes({required String lectorId}) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM $tablaLecturas
      WHERE lector_id = ?
        AND estado_sincronizacion IN ('PENDIENTE','ERROR','SINCRONIZANDO')
      ''',
      [lectorId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> marcarSincronizando(String idLocal) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE $tablaLecturas
      SET estado_sincronizacion = 'SINCRONIZANDO',
          intentos = intentos + 1,
          mensaje_error = NULL
      WHERE id_local = ?
      ''',
      [idLocal],
    );
  }

  Future<void> marcarSincronizada({
    required String idLocal,
    required dynamic respuestaServidor,
  }) async {
    final db = await database;
    await db.update(
      tablaLecturas,
      {
        'estado_sincronizacion': 'SINCRONIZADA',
        'fecha_sincronizacion': DateTime.now().toIso8601String(),
        'mensaje_error': null,
        'respuesta_servidor': jsonEncode(respuestaServidor),
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> marcarError({
    required String idLocal,
    required String mensaje,
  }) async {
    final db = await database;
    await db.update(
      tablaLecturas,
      {
        'estado_sincronizacion': 'ERROR',
        'mensaje_error': mensaje,
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> restaurarLecturasInterrumpidas() async {
    final db = await database;
    await db.update(
      tablaLecturas,
      {
        'estado_sincronizacion': 'PENDIENTE',
        'mensaje_error': 'Sincronización interrumpida. Se reintentará.',
      },
      where: 'estado_sincronizacion = ?',
      whereArgs: ['SINCRONIZANDO'],
    );
  }

  Map<String, dynamic>? decodificarReciboEstimado(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(value.toString());
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  Future<void> eliminarLecturasSincronizadas({
    required String lectorId,
  }) async {
    final db = await database;
    await db.delete(
      tablaLecturas,
      where: "lector_id = ? AND estado_sincronizacion = 'SINCRONIZADA'",
      whereArgs: [lectorId],
    );
  }

  Future<void> cerrar() async {
    final db = _database;
    if (db != null && db.isOpen) await db.close();
    _database = null;
  }
}
