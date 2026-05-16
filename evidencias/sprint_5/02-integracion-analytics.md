# Sprint 5 · Integración Analytics

Dos integraciones distintas trabajando en paralelo:

1. **Firebase Analytics** — recibe cada evento del `AnalyticsService` (login, crear producto, navegar a pantalla, etc.). Datos para reportes históricos y embudo, visibles en el panel de Firebase.
2. **Tabla `audit_log` en el backend** — registra cada request HTTP + cada intento de login. Datos para la pestaña "Seguridad" del dashboard interno.

## 1. Firebase Analytics (cliente)

### Package
```yaml
# pubspec.yaml
dependencies:
  firebase_analytics: ^10.10.7
```

### Sink real
[`lib/core/services/analytics_service.dart`](../../lib/core/services/analytics_service.dart):

```dart
class FirebaseAnalyticsSink implements AnalyticsSink {
  FirebaseAnalyticsSink({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> log(AnalyticsEvent event, Map<String, Object?> params) async {
    // Firebase rechaza null y tipos no primitivos — saneamos antes de enviar.
    final sanitized = <String, Object>{};
    params.forEach((key, value) {
      if (value == null) return;
      if (value is num || value is String || value is bool) {
        sanitized[key] = value;
      } else {
        sanitized[key] = value.toString();
      }
    });
    await _analytics.logEvent(
      name: event.name,
      parameters: sanitized.isEmpty ? null : sanitized,
    );
  }

  Future<void> setUserId(String? uid) async {
    await _analytics.setUserId(id: uid);
  }
}
```

### Configuración en bootstrap
[`lib/main.dart`](../../lib/main.dart):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final analyticsObserver = _configureAnalytics();

  final authProvider = AuthProvider();
  _router = AppRoutes.createRouter(
    authProvider,
    observers: analyticsObserver == null ? const [] : [analyticsObserver],
  );
  // ...
}

FirebaseAnalyticsObserver? _configureAnalytics() {
  try {
    final firebaseSink = FirebaseAnalyticsSink();
    AnalyticsService.instance.configure([
      ConsoleAnalyticsSink(),  // sigue activo en debug
      firebaseSink,
    ]);

    // UID sincronizado con cambios de sesión.
    FirebaseAuth.instance.userChanges().listen((user) {
      firebaseSink.setUserId(user?.uid);
    });

    return FirebaseAnalyticsObserver(analytics: firebaseSink.analytics);
  } catch (e) {
    // Si Analytics falla (ej. measurementId faltante en web), la app
    // sigue funcionando con el ConsoleSink — no aborta el arranque.
    return null;
  }
}
```

### Qué llega automáticamente a Firebase

| Fuente | Evento | Cuándo |
|---|---|---|
| `FirebaseAnalyticsObserver` (vía go_router) | `screen_view` | Al entrar a `login`, `register`, `dashboard`, `analytics` |
| `auth_provider.dart` `signIn` | `login_success` / `login_failed` | Cada intento de login con email |
| `auth_provider.dart` `signInWithGoogle` | `login_success` / `login_failed` | Cada intento con Google |
| `inventory_repository.dart` `createProduct` | `product_created` | Cada producto creado |
| `analytics_dashboard_page.dart` `initState` | `screen_viewed` (manual) | Refuerza la pantalla del dashboard |

### Validación en consola de Firebase
1. **Android/iOS** funcionan out-of-the-box — `google-services.json` / `GoogleService-Info.plist` ya tienen lo necesario.
2. **Web** requiere `measurementId` en `firebase_options.dart`. Si no está, los eventos web no se envían (pero los móviles sí). Para añadirlo: Firebase Console → Project Settings → Web app → copiar `G-XXXXXXXXXX` y re-correr `flutterfire configure`.
3. Para ver eventos en tiempo real: Firebase Console → Analytics → DebugView (instantáneo en `flutter run` debug mode).

## 2. `audit_log` (backend)

### Por qué un segundo canal de analítica
Firebase Analytics es **opcional, externo, agregado** — útil para dashboards de marketing. La tabla `audit_log` es **interna, granular, sincrónica** — alimenta el panel de Seguridad del dueño del producto en tiempo real, sin depender de Firebase.

### Esquema
[`backend/src/db.js`](../../backend/src/db.js):

```sql
CREATE TABLE audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  event_type TEXT NOT NULL,           -- 'api_call' | 'login_attempt'
  usuario_id TEXT,                    -- uid si autenticado
  email TEXT,                         -- login attempts
  method TEXT, path TEXT,             -- api_call
  status_code INTEGER,
  success INTEGER,
  ip_address TEXT, user_agent TEXT,
  error_message TEXT,
  duration_ms INTEGER
);
CREATE INDEX idx_audit_timestamp ON audit_log(timestamp);
CREATE INDEX idx_audit_event_type ON audit_log(event_type);
```

### Cómo se llena
- **`api_call`**: middleware [`backend/src/middleware/audit.js`](../../backend/src/middleware/audit.js) intercepta `res.on('finish')` de cada request (excepto `/health` y la propia ruta de login-attempt para no auto-auditarse) y persiste método, path, status, duración, uid, IP, user-agent.
- **`login_attempt`**: el cliente Flutter llama a [`POST /api/security/login-attempt`](../../backend/src/routes/security.js) **después de cada intento** (éxito o fallo). Esta ruta es pública porque los intentos fallidos no tienen token. La llamada se hace con `unawaited(...)` para no bloquear la UI; si el reporte falla, el login del usuario sigue su curso.

### Quién lo lee
[`backend/src/routes/analytics.js`](../../backend/src/routes/analytics.js) expone `GET /api/analytics/security` con queries agregadas (counts, joins, group by). El cliente lo consume desde [`analytics_repository.dart`](../../lib/features/analytics/data/analytics_repository.dart) `loadSecurity()` y lo renderiza en la pestaña Seguridad del dashboard.

## Por qué no son redundantes

| Pregunta | Firebase Analytics | `audit_log` |
|---|---|---|
| ¿Cuántos usuarios entraron a la app esta semana? | ✅ | ❌ (solo loguea quien intentó) |
| ¿Cuál es la pantalla más visitada? | ✅ (`screen_view`) | ❌ |
| ¿Cuántas requests recibió mi backend en las últimas 24h? | ❌ | ✅ |
| ¿Qué endpoint se cae con más errores 5xx? | ❌ | ✅ |
| ¿Hay un patrón de intentos fallidos desde una IP? | ❌ | ✅ |
| ¿Cuántos productos se han creado este mes? | ✅ (eventos) | parcial (via `POST /api/products`) |

Firebase responde "qué hace mi usuario". `audit_log` responde "qué le está pasando a mi backend". Las dos son útiles, y ninguna reemplaza a la otra.

## Decisiones de diseño

- **Tres sinks coexistiendo**: `ConsoleAnalyticsSink` queda activo en debug junto a Firebase — útil para verificar localmente sin abrir DebugView.
- **Errores absorbidos**: `AnalyticsService.log` nunca relanza. Una falla de red en analítica no debe abortar la creación del producto.
- **`@visibleForTesting InMemoryAnalyticsSink`**: tests pueden hacer `AnalyticsService.instance.configure([InMemoryAnalyticsSink()])` y verificar `calls`.
- **Auditoría síncrona dentro del request**: `res.on('finish')` corre antes de cerrar la conexión, así garantiza orden temporal correcto. Si el INSERT a `audit_log` falla, solo se loguea — nunca tumba la response.
- **Login attempt como ruta pública**: necesario porque los intentos fallidos no tienen token. Riesgo: alguien podría spammear la ruta. Mitigaciones futuras: rate limiting (`express-rate-limit`) o captcha en el client.
