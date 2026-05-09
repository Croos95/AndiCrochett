/// Configuración de entorno de la aplicación.
/// En producción, considera usar flutter_dotenv o --dart-define
/// para no hardcodear valores sensibles.
class Env {
  // Nombre de la app
  static const String appName = 'AndiCrochett';
  static const String appVersion = '0.1.0';

  // API base URL.
  // - Desarrollo: usa localhost por defecto.
  // - Produccion: exige BASE_URL por --dart-define y HTTPS obligatorio.
  static const String _baseUrlFromEnv = String.fromEnvironment('BASE_URL');
  static const String _devBaseUrl = 'http://localhost:3000/api';

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
