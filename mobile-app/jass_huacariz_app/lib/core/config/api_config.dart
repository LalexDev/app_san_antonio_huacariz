class ApiConfig {
  // Emulador por defecto. Para celular/Tailscale/producción usa:
  // flutter run --dart-define=API_BASE_URL=http://100.x.x.x:8080/api
  // flutter build apk --dart-define=API_BASE_URL=https://api.midominio.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  static const String health = '/health';

  // AUTENTICACIÓN DEL PERSONAL
  static const String login = '/auth/login';

  // PORTAL DEL CLIENTE
  static const String clienteMe = '/cliente/me';

  static const String clienteMeSuministros = '/cliente/me/suministros';

  static const String clienteMeRecibos = '/cliente/me/recibos';

  static String clienteMeReciboPdf(int idRecibo) {
    return '/cliente/me/recibos/$idRecibo/pdf';
  }

  static String clienteMePagarRecibo(int idRecibo) {
    return '/cliente/me/recibos/$idRecibo/pagar';
  }

  static const String clienteMePassword = '/cliente/me/password';

  // ADMINISTRACIÓN DE CLIENTES Y SUMINISTROS
  // Los clientes continúan como registros administrados por el ADMIN,
  // pero ya no tienen acceso al aplicativo móvil.
  static const String clientes = '/clientes';

  static String clientePorId(int idCliente) {
    return '/clientes/$idCliente';
  }

  static String suministrosPorCliente(int idCliente) {
    return '/clientes/$idCliente/suministros';
  }

  static String cambiarEstadoCliente(
    int idCliente,
    bool estado,
  ) {
    return '/clientes/$idCliente/estado?estado=$estado';
  }

  static String cambiarEstadoSuministro({
    required int idCliente,
    required int idSuministro,
    required bool estado,
  }) {
    return '/clientes/$idCliente/suministros/'
        '$idSuministro/estado?estado=$estado';
  }

  // ADMINISTRACIÓN DE RECIBOS
  static const String recibos = '/recibos';
  static const String recibosPendientes = '/recibos/pendientes';

  // CANALES DE PAGO
  static const String canalesPago = '/canales-pago';

  static const String canalesPagoActivos = '/canales-pago/activos';

  static String recibosPorSuministro(
    String codigoSuministro,
  ) {
    return '/recibos/suministro/$codigoSuministro';
  }

  static String pagarReciboAdmin(int idRecibo) {
    return '/recibos/$idRecibo/pagar';
  }

  // PAGOS ADMINISTRATIVOS
  static const String pagos = '/pagos';

  static String pagosPorSuministro(
    String codigoSuministro,
  ) {
    return '/pagos/suministro/$codigoSuministro';
  }

  // TARIFAS Y CONFIGURACIÓN DE COBRANZA
  static const String tarifas = '/tarifas';

  static String tarifaPorId(int idTarifa) {
    return '/tarifas/$idTarifa';
  }

  static String cambiarEstadoTarifa(
    int idTarifa,
    bool estado,
  ) {
    return '/tarifas/$idTarifa/estado?estado=$estado';
  }

  static const String configuracionCobranza =
      '/configuracion-cobranza';

  // SECTORES
  static const String sectores = '/sectores';

  static String sectorPorId(int idSector) {
    return '/sectores/$idSector';
  }

  static String cambiarEstadoSector(
    int idSector,
    bool estado,
  ) {
    return '/sectores/$idSector/estado?estado=$estado';
  }

  // ADMINISTRACIÓN DE LECTURADORES
  static const String lecturadores =
      '/usuarios/lecturadores';

  static String lecturadorPorId(int idLecturador) {
    return '/usuarios/lecturadores/$idLecturador';
  }

  static String cambiarEstadoLecturador(
    int idLecturador,
    bool estado,
  ) {
    return '/usuarios/lecturadores/'
        '$idLecturador/estado?estado=$estado';
  }

  // OPERACIÓN DEL LECTURADOR
  static String buscarSuministroLecturador(
    String codigoSuministro,
  ) {
    return '/lecturador/suministros/$codigoSuministro';
  }

  static const String suministrosOfflineLecturador =
      '/lecturador/suministros/offline';

  static const String registrarLectura = '/lecturas';
  static const String registrarMantenimiento =
      '/lecturas/mantenimiento';

  // Ruta compartida por ADMIN y LECTURADOR.
  static const String historialLecturas =
      '/lecturas/historial';
  static const String historialLecturasAdmin =
      historialLecturas;
}
