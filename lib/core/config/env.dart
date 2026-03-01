/// Configuración de entorno de la aplicación.
/// En producción, considera usar flutter_dotenv o --dart-define
/// para no hardcodear valores sensibles.
class Env {
  // Nombre de la app
  static const String appName = 'AndiCrochett';
  static const String appVersion = '0.1.0';

  // API base URL — reemplaza con tu endpoint real
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

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
