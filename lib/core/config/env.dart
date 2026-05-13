import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuración de entorno de la aplicación.
/// En producción, considera usar flutter_dotenv o --dart-define
/// para no hardcodear valores sensibles.
class Env {
  // Nombre de la app
  static const String appName = 'AndiCrochett';
  static const String appVersion = '0.1.0';

  // API base URL.
  // - Desarrollo: autodetecta la plataforma para conectar al backend local.
  // - Produccion: exige BASE_URL por --dart-define y HTTPS obligatorio.
  static const String _baseUrlFromEnv = String.fromEnvironment('BASE_URL');

  /// URL base para desarrollo según la plataforma de ejecución:
  /// - Web / iOS Simulator / Desktop: `localhost` apunta a la PC.
  /// - Android emulator: `10.0.2.2` es el alias del host (la PC) desde el emulador.
  /// Para un dispositivo Android físico, sobrescribe con `--dart-define=BASE_URL=http://IP-LAN:3000/api`
  static String get _devBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static String get baseUrl {
    final resolvedBaseUrl = _baseUrlFromEnv.isNotEmpty
        ? _baseUrlFromEnv
        : (isProduction ? '' : _devBaseUrl);

    if (isProduction) {
      if (resolvedBaseUrl.isEmpty) {
        throw StateError(
          'BASE_URL no esta configurado para produccion. '
          'Define --dart-define=BASE_URL=https://tu-api-segura.com/api',
        );
      }
      if (!resolvedBaseUrl.startsWith('https://')) {
        throw StateError(
          'BASE_URL debe usar HTTPS en produccion. Valor recibido: '
          '$resolvedBaseUrl',
        );
      }
    }

    return resolvedBaseUrl;
  }

  // Tiempo de espera de peticiones (ms)
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 15000;

  /// Intervalo entre refrescos automáticos de los streams basados en polling.
  /// Cada repositorio lo usa para programar el siguiente fetch.
  /// Subirlo reduce tráfico al backend; bajarlo da más sensación de tiempo real.
  static const Duration pollInterval = Duration(seconds: 3);

  // Claves de almacenamiento local
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';

  // Flags de entorno
  static const bool isProduction = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );
  static bool get isDevelopment => !isProduction;
}
