// =============================================================================
//  ApiService
//  Cliente HTTP centralizado para llamadas a la API REST del backend.
//
//  Estado: PENDIENTE DE IMPLEMENTACIÓN (sprint futuro).
//  Actualmente toda la persistencia se maneja vía Firestore;
//  este servicio se activará cuando se integre el backend Node.js.
//
//  Dependencia sugerida: 'dio' o 'http' según la complejidad requerida.
//  La URL base y timeouts están definidos en [Env].
// =============================================================================

// import 'package:andicrochett/core/config/env.dart';

/// [ApiService] centraliza todas las peticiones HTTP salientes.
/// Aplica interceptores de autenticación, manejo de errores y retries.
class ApiService {
  // TODO: Inicializar cliente HTTP con baseUrl = Env.baseUrl y
  //       connectTimeout = Env.connectTimeout.
}
