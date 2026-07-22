import 'package:flutter/material.dart';

import 'core/app_theme_controller.dart';
import 'shared/theme/jass_colors.dart';

import 'features/auth/login_page.dart';

import 'features/admin/admin_dashboard_page.dart';
import 'features/admin/admin_clientes_page.dart';
import 'features/admin/admin_lecturadores_page.dart';
import 'features/admin/admin_sectores_page.dart';
import 'features/admin/admin_pagos_page.dart';
import 'features/admin/admin_qr_suministro_page.dart';
import 'features/admin/admin_tarifas_page.dart';
import 'features/admin/admin_recibos_page.dart';
import 'features/admin/admin_reportes_page.dart';

import 'features/lector/lector_home_page.dart';
import 'features/lector/buscar_suministro_page.dart';
import 'features/lector/detalle_suministro_page.dart';
import 'features/lector/registrar_lectura_page.dart';
import 'features/lector/comprobante_recibo_page.dart';
import 'features/lector/historial_lecturas_page.dart';
import 'features/lector/qr_scanner_page.dart';

class JassHuacarizApp extends StatelessWidget {
  const JassHuacarizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'AGUA POTABLE HUACARIZ SAN ANTONIO',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: JassColors.background,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.light,
              seedColor: JassColors.secondary,
              primary: JassColors.primary,
              secondary: JassColors.secondary,
              surface: JassColors.card,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: JassColors.darkBackground,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: JassColors.secondary,
              primary: JassColors.secondary,
              secondary: JassColors.accent,
              surface: JassColors.darkCard,
            ),
          ),
          initialRoute: '/login',
          routes: {
            // AUTENTICACIÓN DEL PERSONAL
            '/login': (_) => const LoginPage(),

            // ADMINISTRADOR
            '/admin-dashboard': (_) => const AdminDashboardPage(),
            '/admin-clientes': (_) => const AdminClientesPage(),
            '/admin-lecturadores': (_) => const AdminLecturadoresPage(),
            '/admin-sectores': (_) => const AdminSectoresPage(),
            '/admin-pagos': (_) => const AdminPagosPage(),
            '/admin-qr-suministro': (_) => const AdminQrSuministroPage(),
            '/admin-tarifas': (_) => const AdminTarifasPage(),
            '/admin-recibos': (_) => const AdminRecibosPage(),
            '/admin-reportes': (_) => const AdminReportesPage(),

            // PANTALLAS COMPARTIDAS ABIERTAS DESDE ADMINISTRADOR
            '/admin-historial-lecturas': (_) =>
                const HistorialLecturasPage(modoAdmin: true),
            '/admin-qr-scanner': (_) =>
                const QrScannerPage(modoAdmin: true),
            '/admin-buscar-suministro': (_) =>
                const BuscarSuministroPage(modoAdmin: true),
            '/admin-detalle-suministro': (_) =>
                const DetalleSuministroPage(modoAdmin: true),
            '/admin-registrar-lectura': (_) =>
                const RegistrarLecturaPage(modoAdmin: true),
            '/admin-comprobante-recibo': (_) =>
                const ComprobanteReciboPage(modoAdmin: true),

            // LECTURADOR
            '/lector-home': (_) => const LectorHomePage(),
            '/buscar-suministro': (_) =>
                const BuscarSuministroPage(modoAdmin: false),
            '/qr-scanner': (_) =>
                const QrScannerPage(modoAdmin: false),
            '/detalle-suministro': (_) =>
                const DetalleSuministroPage(modoAdmin: false),
            '/registrar-lectura': (_) =>
                const RegistrarLecturaPage(modoAdmin: false),
            '/comprobante-recibo': (_) =>
                const ComprobanteReciboPage(modoAdmin: false),
            '/historial-lecturas': (_) =>
                const HistorialLecturasPage(modoAdmin: false),
          },
          onUnknownRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const LoginPage(),
            settings: const RouteSettings(name: '/login'),
          ),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const JassHuacarizApp();
  }
}
