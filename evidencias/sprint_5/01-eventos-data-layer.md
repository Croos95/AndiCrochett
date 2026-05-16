# Sprint 5 · Eventos (Data Layer)

Toda la app emite eventos a través de un único punto: [`AnalyticsService`](../../lib/core/services/analytics_service.dart). El catálogo está cerrado (enum), así que el linter detecta cualquier evento inválido en tiempo de compilación.

## Taxonomía actual

| Categoría | Evento | Nombre snake_case |
|---|---|---|
| Autenticación | `loginSuccess` | `login_success` |
|  | `loginFailed` | `login_failed` |
|  | `signUpSuccess` | `sign_up_success` |
|  | `logoutSuccess` | `logout_success` |
| Inventario | `productCreated` | `product_created` |
|  | `productUpdated` | `product_updated` |
|  | `productDeleted` | `product_deleted` |
|  | `productSearched` | `product_searched` |
| Pedidos | `orderCreated` | `order_created` |
|  | `orderStatusChanged` | `order_status_changed` |
|  | `orderCancelled` | `order_cancelled` |
| Patrones / Diseños | `patternCreated` | `pattern_created` |
|  | `designCreated` | `design_created` |
| Navegación | `screenViewed` | `screen_viewed` |

**14 eventos** definidos en el enum [`AnalyticsEvent`](../../lib/core/services/analytics_service.dart).

## Helpers tipados
El servicio expone wrappers que forzan los parámetros correctos:

```dart
AnalyticsService.instance.logProductCreated(productId: 9, name: 'Estambre rojo');
AnalyticsService.instance.logOrderCreated(orderId: 1, total: 199.99, itemCount: 3);
AnalyticsService.instance.logLogin(method: 'email', success: true);
AnalyticsService.instance.logScreen('analytics_dashboard');
```

Esto evita errores tipográficos en parámetros (`product_id` vs `productId`) y garantiza que el contrato con BI sea estable.

## Sinks (fan-out)
`AnalyticsService` despacha cada evento a **todos** los sinks registrados. Las implementaciones provistas:

- **`ConsoleAnalyticsSink`** (default en debug) — imprime con `debugPrint` cuando `kDebugMode` es true. En release es silencioso.
- **`FirebaseAnalyticsSink`** — implementación real (no stub). Delega a `FirebaseAnalytics.instance.logEvent(...)` con saneamiento de tipos (Firebase rechaza `null` y tipos no primitivos). Detalles en [02-integracion-analytics.md](02-integracion-analytics.md).
- **`InMemoryAnalyticsSink`** — `@visibleForTesting`, guarda los calls en una lista para verificar en pruebas.

Un sink puede lanzar excepción sin tumbar a los demás — el servicio captura y solo loggea. La analítica nunca debe romper una feature de producto.

## Wiring real

Los siguientes call sites están conectados a `AnalyticsService` y emiten eventos en producción:

| Call site | Evento | Cuándo |
|---|---|---|
| [`inventory_repository.dart`](../../lib/features/inventory/data/repositories/inventory_repository.dart) `createProduct` | `product_created` | Al insertar producto |
| [`auth_provider.dart`](../../lib/features/auth/presentation/providers/auth_provider.dart) `signIn` | `login_success` / `login_failed` | Cada intento de login con email |
| [`auth_provider.dart`](../../lib/features/auth/presentation/providers/auth_provider.dart) `signInWithGoogle` | `login_success` / `login_failed` | Cada intento con Google |
| [`analytics_dashboard_page.dart`](../../lib/features/analytics/presentation/pages/analytics_dashboard_page.dart) `initState` | `screen_viewed` | Al entrar al dashboard |
| `FirebaseAnalyticsObserver` (en [`main.dart`](../../lib/main.dart)) | `screen_view` (SDK) | Automático al cambiar de ruta en `go_router` |

Por ejemplo, cuando se crea un producto, sale por consola en debug:
```
[analytics] product_created {product_id: 9, name: Estambre rojo}
```

Y simultáneamente Firebase Analytics lo recibe como evento `product_created` con esos parámetros.

## Reporte adicional al backend (audit_log)

Además del fan-out a Firebase, los intentos de login también se reportan al backend propio vía [`SecurityReporter`](../../lib/core/services/security_reporter.dart) → `POST /api/security/login-attempt`. Esto alimenta la sección **Seguridad** del dashboard interno. Ver [02-integracion-analytics.md](02-integracion-analytics.md) para detalles.

## Próximas extensiones sugeridas

Los siguientes eventos están en la taxonomía pero aún no tienen call sites — agregarlos es trivial (una línea cada uno):

- `orderCreated` / `orderStatusChanged` / `orderCancelled` en `OrderRepository`.
- `patternCreated` / `designCreated` en sus respectivos repos.
- `productUpdated` / `productDeleted` / `productSearched` en `InventoryRepository`.

## Pruebas

[`test/unit/services/analytics_service_test.dart`](../../test/unit/services/analytics_service_test.dart) cubre:

- Nombres snake_case estables (contrato con BI).
- `log` delega al sink con event + params.
- Helpers tipados arman el payload correcto.
- `logLogin` escoge `success` vs `failed` según el flag.
- Fan-out a múltiples sinks.
- Un sink que lanza excepción no detiene a los demás.

**7 tests pasando.**
