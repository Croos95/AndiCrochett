# Sprint 3 · Cliente Dart seguro

## El problema
Cada componente Flutter que quiera llamar a `/api/secure/*` necesita:
1. Obtener el ID token actual del usuario.
2. Manejar tokens expirados (refresh).
3. Construir la URL con `baseUrl`.
4. Parsear respuestas y errores.

Hacerlo en cada call site es tedioso y propenso a errores. Centralizamos en [`SecureApiClient`](../../lib/core/services/secure_api_client.dart).

## API

```dart
final client = SecureApiClient(baseUrl: Env.baseUrl);

// GET /api/secure/me — devuelve el usuario decoded por el middleware.
final me = await client.getSecure('/me');
print(me['user']['email']);

// GET /api/secure/ping — health autenticado.
final ping = await client.getSecure('/ping');
```

`baseUrl` viene de `Env.baseUrl` (que ya exige HTTPS en producción — ver [02-https-local.md](02-https-local.md)).

## Cómo inyecta el token
```dart
Future<String> _idToken() async {
  final user = _auth.currentUser;
  if (user == null) throw StateError(...);
  final token = await user.getIdToken();
  if (token == null || token.isEmpty) throw StateError(...);
  return token;
}

Future<Map<String, dynamic>> getSecure(String path) async {
  final token = await _idToken();
  final res = await _client.get(uri, headers: {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  });
  ...
}
```

- `FirebaseAuth.instance.currentUser.getIdToken()` devuelve el token vigente, refrescándolo si está próximo a expirar (esa lógica vive en el SDK de Firebase, no la duplicamos).
- Si no hay usuario, **fallamos rápido** con `StateError`. La app debe chequear `isAuthenticated` antes de llamar.

## Manejo de errores
```dart
class SecureApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? body;
  ...
}
```

Las respuestas no-2xx se convierten a `SecureApiException` con el JSON parseado del backend. El consumidor puede distinguir por `statusCode`:

```dart
try {
  await client.getSecure('/me');
} on SecureApiException catch (e) {
  if (e.statusCode == 401) {
    // Token expirado o inválido — relogear.
  } else if (e.statusCode == 403) {
    // Origen bloqueado por CORS o permiso insuficiente.
  }
}
```

## Diseño testeable
El constructor acepta `http.Client?` y `FirebaseAuth?` opcionales:

```dart
SecureApiClient({
  required this.baseUrl,
  http.Client? client,
  FirebaseAuth? auth,
})
```

Esto permite, en pruebas, inyectar un `MockClient` de `http/testing` y un `FirebaseAuth` fake.

## Por qué no se cablea en el InventoryRepository todavía
Los repositorios actuales (`InventoryRepository`, `OrderRepository`) trabajan **directo contra SQLite local**, no contra la API. El `SecureApiClient` queda listo para cuando se migre alguna feature a backend remoto (Sprint 2 — endpoints REST reales). Mientras tanto:

- La app sigue funcionando 100% offline-first.
- El cliente está disponible para features que sí lo necesiten (p. ej. compartir patrones entre dispositivos).

## Próxima integración natural
Cuando el Sprint 2 agregue endpoints reales (ej. `GET /api/secure/inventory`), el repositorio puede combinar SQLite + API:

```dart
class InventoryRepository {
  Future<List<ProductModel>> sync() async {
    final remote = await _client.getSecure('/inventory');
    // merge remote → SQLite local
    return getAllProducts();
  }
}
```

Esa transición no requiere tocar `SecureApiClient` — el contrato ya está listo.
