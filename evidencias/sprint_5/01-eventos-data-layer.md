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

- **`ConsoleAnalyticsSink`** (default) — imprime con `debugPrint` cuando `kDebugMode` es true. En release es silencioso.
- **`FirebaseAnalyticsSink`** — stub que documenta exactamente dónde delegar a `FirebaseAnalytics.instance.logEvent(...)`.
- **`InMemoryAnalyticsSink`** — `@visibleForTesting`, guarda los calls en una lista para verificar en pruebas.

Un sink puede lanzar excepción sin tumbar a los demás — el servicio captura y solo loggea. La analítica nunca debe romper una feature de producto.

## Wiring de ejemplo
Hoy hay un solo call site real (intencional, para demostrar el patrón sin contaminar toda la base):

```dart
// lib/features/inventory/data/repositories/inventory_repository.dart
Future<int> createProduct(ProductModel product) async {
  final id = await _db.addProduct(product.toMap());
  AnalyticsService.instance.logProductCreated(productId: id, name: product.name);
  return id;
}
```

Cada vez que se crea un producto, sale por consola en debug:
```
[analytics] product_created {product_id: 9, name: Estambre rojo}
```

## Próximos pasos sugeridos
1. Hookear `logLogin` en `AuthProvider.signIn` (success/failure).
2. Hookear `logOrderCreated` en `OrderRepository.create`.
3. Hookear `logScreen` en cada ruta de `go_router` (vía `observer`).

Esos call sites son una línea cada uno — el costo marginal es bajo y la cobertura analítica crece linealmente.

## Pruebas
[`test/unit/services/analytics_service_test.dart`](../../test/unit/services/analytics_service_test.dart) cubre:

- Nombres snake_case estables (contrato con BI).
- `log` delega al sink con event + params.
- Helpers tipados arman el payload correcto.
- `logLogin` escoge `success` vs `failed` según el flag.
- Fan-out a múltiples sinks.
- Un sink que lanza excepción no detiene a los demás.

**8 tests pasando.**
