# JASS Huacariz — Aplicación móvil del personal

Aplicación Flutter destinada exclusivamente a dos perfiles:

- **ADMINISTRADOR**: gestión de clientes, suministros, lecturadores, sectores, tarifas, recibos, pagos, reportes y lecturas.
- **LECTURADOR / LECTOR**: búsqueda y escaneo de suministros, registro de lecturas, mantenimiento, historial y funcionamiento offline.

## Acceso eliminado

El portal y el inicio de sesión del rol **CLIENTE** fueron retirados de la aplicación móvil. Los clientes continúan existiendo como registros del sistema y son administrados desde el módulo del administrador, pero no pueden iniciar sesión en esta app.

## Ejecución

```bat
flutter clean
flutter pub get
flutter analyze
flutter run
```

Para usar un backend por Tailscale o red local:

```bat
flutter run --dart-define=API_BASE_URL=http://100.x.x.x:8080/api
```

## Modo offline

El acceso sin conexión está habilitado únicamente para el lecturador que haya iniciado sesión previamente con conexión en ese dispositivo.
