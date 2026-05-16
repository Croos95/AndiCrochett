# Sprint 3 · Cliente Dart seguro

## El problema
Cada componente Flutter que quiera llamar al backend necesita:
1. Obtener el ID token actual del usuario.
2. Manejar tokens expirados (refresh).
3. Construir la URL con `baseUrl`.
4. Parsear respuestas y errores.
5. Adjuntar el header `Authorization` consistentemente.

Hacerlo en cada call site es tedioso y propenso a errores. Lo centralizamos en [`ApiClient`](../../lib/core/services/api_client.dart).

## API

```dart
// Singleton listo para usar:
final api = ApiClient.instance;

// O instancia propia (útil en tests):
final api = ApiClient(
  baseUrl: 'http://test.local/api',
  client: MockClient((req) async => ...),
  tokenProvider: () async => 'fake-token',
);
```

Métodos:

```dart
await api.get('/designs');                          // → List o Map
await api.get('/patterns', query: {'designId': 1});
await api.post('/designs', body: {'nombre': 'X'});
await api.put('/designs/1', body: {'nombre': 'Y'});
await api.patch('/products/1/stock', body: {'cantidad': 0});
await api.delete('/designs/1');
```

`baseUrl` viene de `Env.baseUrl` (autodetecta plataforma: web/iOS usa `localhost`, Android emulator usa `10.0.2.2`, producción exige HTTPS — ver [02-https-local.md](02-https-local.md)).

## Cómo inyecta el token

```dart
typedef TokenProvider = Future<String> Function();

class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? client,
    FirebaseAuth? auth,
    TokenProvider? tokenProvider,
  })  : _baseUrl = baseUrl ?? Env.baseUrl,
        _client = client ?? http.Client(),
        _tokenProvider = tokenProvider
            ?? _firebaseTokenProvider(auth ?? FirebaseAuth.instance);

  static TokenProvider _firebaseTokenProvider(FirebaseAuth auth) {
    return () async {
      final user = auth.currentUser;
      if (user == null) throw StateError('No hay usuario autenticado');
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw StateError('Firebase devolvió un ID token vacío');
      }
      return token;
    };
  }

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final token = await _tokenProvider();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
  }
}
```

Puntos clave:

- **`FirebaseAuth.instance.currentUser.getIdToken()`** devuelve el token vigente, refrescándolo automáticamente si está cerca de expirar (1h). Esa lógica vive en el SDK de Firebase, no la duplicamos.
- Si no hay usuario, **fallamos rápido** con `StateError`. La UI debe chequear `isAuthenticated` antes de llamar al ApiClient.
- **`tokenProvider` inyectable** para tests — permite pasar `() async => 'fake-token'` sin necesidad de inicializar Firebase en el binding de pruebas.

## Manejo de errores

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;
  ApiException(this.statusCode, this.message, {this.body});
}
```

Las respuestas no-2xx se convierten a `ApiException` con el mensaje del backend ya parseado:

```dart
try {
  await api.get('/designs');
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Token expirado o inválido — relogear.
  } else if (e.statusCode == 400) {
    // e.message contiene el mensaje específico del backend.
    showSnack(e.message);
  } else if (e.statusCode == 404) {
    return null;  // El recurso no existe.
  }
}
```

El parseo del mensaje soporta dos shapes que devuelve el backend:
- `{ "error": "Falta el campo nombre" }` → `e.message = "Falta el campo nombre"`
- `{ "errors": ["x inválido", "y faltante"] }` → `e.message = "x inválido, y faltante"`

## Cableado real en repositorios

A diferencia de la versión original del sprint (donde el `SecureApiClient` quedó listo pero sin cablear), `ApiClient` **es la columna vertebral de TODA la capa de datos del cliente**. Los repositorios lo consumen vía DI:

```dart
class DesignRepository {
  DesignRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<List<DesignModel>> getAll() async {
    final data = await _api.get('/designs') as List<dynamic>;
    return data.map((m) => DesignModel.fromMap(m as Map<String, dynamic>)).toList();
  }
}
```

Repositorios migrados a `ApiClient`:
- `DesignRepository` → `/api/designs`
- `PatternRepository` → `/api/patterns`
- `InventoryRepository` → `/api/products`
- `ClientRepository` → `/api/clients`
- `OrderRepository` → `/api/orders`
- `AnalyticsRepository` → `/api/analytics/dashboard` + `/api/analytics/security`
- `LandingRepository` (ambas variantes) → `/api/catalog`

## Adicional: `SecurityReporter`

Para el reporte de intentos de login (que **no** requieren token), existe un cliente paralelo más minimal:

[`lib/core/services/security_reporter.dart`](../../lib/core/services/security_reporter.dart):

```dart
class SecurityReporter {
  Future<void> reportLoginAttempt({
    required String email,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/security/login-attempt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'success': success, ...}),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      // Nunca relanzamos: no queremos romper el login por un fallo de telemetría.
      debugPrint('[security] no se pudo reportar login attempt: $e');
    }
  }
}
```

Se llama desde [`AuthProvider`](../../lib/features/auth/presentation/providers/auth_provider.dart) con `unawaited(...)` después de cada intento de login (success o fail). El backend lo persiste en `audit_log` y alimenta el dashboard de Seguridad (Sprint 5).

## Pruebas

[`test/unit/services/api_client_test.dart`](../../test/unit/services/api_client_test.dart) cubre el cliente con **7 tests**:

| Test | Verifica |
|---|---|
| `ApiClient.get agrega Authorization Bearer y Accept JSON` | Headers correctos en GET |
| `ApiClient.get serializa query params correctamente` | `?designId=42` se arma bien |
| `ApiClient.get parsea JSON de respuesta` | El body se decodifica como `Map` o `List` |
| `ApiClient.post envía body JSON y Content-Type` | POST con body serializado |
| `lanza ApiException con mensaje del backend en 4xx` | Shape `{error: "..."}` |
| `lanza ApiException con lista de errores cuando viene "errors"` | Shape `{errors: [...]}` |
| `propaga error de token cuando tokenProvider falla` | StateError fluye correctamente |

Todos los tests usan `MockClient` de `http/testing.dart` y `tokenProvider` inyectado — **cero dependencias de red ni Firebase real**.

## Por qué este diseño aguanta la migración

Cuando reemplazamos Cloud Functions por backend Node propio, **solo cambió la URL base**. Cada repositorio, cada test, cada call site siguió funcionando idéntico porque hablan con `ApiClient`, no con un cliente específico de Firebase.

La capa de abstracción pagó su costo.
