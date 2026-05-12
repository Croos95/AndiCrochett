# Sprint 5 · Integración Analytics

## Por qué no se instaló `firebase_analytics` todavía
El package `firebase_analytics` requiere configuración nativa adicional en Android, iOS y Web (regenerar `GoogleService-Info.plist`, agregar el plugin a `build.gradle`, etc.). Hacerlo sin un ambiente donde podamos verificar end-to-end que los eventos llegan al panel de Firebase introduce riesgo de "verde en CI, vacío en consola".

El diseño actual deja **todo el cableado listo** para conectarlo cuando el equipo decida abrir el panel de Analytics — el cambio es un solo archivo.

## Cómo conectarlo (cuando se decida)

### Paso 1: agregar el package
```yaml
# pubspec.yaml
dependencies:
  firebase_analytics: ^10.10.7
```

### Paso 2: reemplazar el stub
```dart
// lib/core/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsSink implements AnalyticsSink {
  @override
  Future<void> log(AnalyticsEvent event, Map<String, Object?> params) async {
    await FirebaseAnalytics.instance.logEvent(
      name: event.name,
      parameters: params.cast<String, Object>(),
    );
  }
}
```

### Paso 3: registrarlo al iniciar
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  AnalyticsService.instance.configure([
    ConsoleAnalyticsSink(),
    FirebaseAnalyticsSink(),
  ]);

  // ...resto del bootstrap
}
```

### Paso 4: validar en la consola de Firebase
1. Activar la propiedad de Analytics en el proyecto Firebase (Project Settings → Integrations).
2. Ir a Realtime → DebugView.
3. En el dispositivo correr `adb shell setprop debug.firebase.analytics.app <package_name>` (Android) o `-FIRDebugEnabled` (iOS).
4. Disparar un evento desde la app (crear producto) y verificar que aparece en DebugView en < 60s.

## Por qué este diseño no se rompe con la migración

- El **catálogo de eventos** ya vive en `AnalyticsEvent`. Cambiar el sink no toca call sites.
- Los **helpers tipados** (`logProductCreated`, etc.) ya garantizan los parámetros correctos.
- La inicialización del servicio tiene `try/catch` por sink — si Firebase Analytics falla en un dispositivo, el resto de la app sigue funcionando.

## Decisiones de diseño

- **Lista de sinks**, no único: permite mantener `ConsoleAnalyticsSink` activo en debug junto a Firebase, sin doble configuración.
- **Errores absorbidos**: `AnalyticsService.log` nunca relanza errores del sink. Una falla de red en el envío de analítica no debe abortar la creación del producto.
- **`@visibleForTesting InMemoryAnalyticsSink`**: cualquier test que quiera afirmar sobre eventos lo enchufa con `configure([InMemoryAnalyticsSink()])` y verifica `calls`.

## Estado actual
| Pieza | Estado |
|---|---|
| Catálogo de eventos (enum) | Listo |
| `AnalyticsService` con fan-out | Listo |
| `ConsoleAnalyticsSink` (debug) | Listo y activo por default |
| `FirebaseAnalyticsSink` (stub) | Listo, espera el package |
| `InMemoryAnalyticsSink` (testing) | Listo |
| Call site real (createProduct) | Listo, demostrable en consola |
| Package `firebase_analytics` | **Pendiente** — un solo paso |
