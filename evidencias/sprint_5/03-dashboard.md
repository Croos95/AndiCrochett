# Sprint 5 · Dashboard

La página vive en [`/analytics`](../../lib/features/analytics/presentation/pages/analytics_dashboard_page.dart) y se accede vía `go_router`. Está organizada en un `DefaultTabController` con **dos pestañas** que corresponden a las dos fuentes de datos del Sprint:

- **Negocio** — métricas sobre la operación del taller (productos, pedidos, ingresos)
- **Seguridad** — métricas de ciberseguridad sobre el `audit_log` del backend

Ambas pestañas se cargan en paralelo (`Future.wait` implícito) y comparten un botón "Recargar" en la `AppBar`.

## Composición

```
AnalyticsDashboardPage
├── AppBar — título "Analítica" + botón "Recargar"
├── TabBar — [Negocio] [Seguridad]
└── TabBarView
    ├── _BusinessTab (FutureBuilder<DashboardMetrics>)
    │   ├── Resumen — 6 MetricCard
    │   ├── Conversión de ingresos (CurrencyConversionCard — API externa)
    │   ├── Pedidos por estado (StatusBreakdownBar)
    │   ├── Top productos vendidos (ListTile · 5)
    │   └── Productos por reabastecer (ListTile · hasta 10)
    └── _SecurityTab (FutureBuilder<SecurityMetrics>)
        ├── Intentos de login (7d) — 4 MetricCard
        ├── Llamadas a la API (24h) — 5 MetricCard
        ├── Endpoints más usados (ListTile · 5)
        └── Logins fallidos recientes (ListTile · hasta 10)
```

## Pestaña Negocio — fuente y fórmulas

Endpoint: `GET /api/analytics/dashboard` ([backend/src/routes/analytics.js](../../backend/src/routes/analytics.js)).

| MetricCard | Fórmula SQL | Acción que dispara |
|---|---|---|
| Productos | `SELECT COUNT(*) FROM productos` | Crecimiento del catálogo |
| Bajo stock | `WHERE estado = 'low_stock'` | Reabastecer pronto |
| Sin existencias | `WHERE estado = 'out_of_stock'` | Reabastecer YA |
| Pedidos totales | `SELECT COUNT(*) FROM pedidos` | Volumen histórico |
| Clientes | `SELECT COUNT(*) FROM clientes` | Tamaño de la base |
| Ingresos 30 días | `SUM(total) WHERE estado='completed' AND fecha_pedido >= now-30d` | Salud financiera reciente |

### Pedidos por estado
Barra horizontal proporcional + leyenda. Colores fijos por estado:
- **Amarillo** — pending
- **Azul** — inProgress
- **Verde** — completed
- **Rojo** — cancelled

Implementación: `Row` con `Expanded(flex: count)`. Sin librerías de charts — mantenerlo simple evita romper builds web por incompatibilidades de canvas.

### Top productos
```sql
SELECT nombre_producto, SUM(cantidad) AS units,
       SUM(cantidad * precio_unitario) AS revenue
FROM items_pedido
GROUP BY nombre_producto
ORDER BY units DESC
LIMIT 5
```

### Productos por reabastecer (nuevo)
```sql
SELECT id, nombre, cantidad, estado
FROM productos
WHERE estado IN ('low_stock', 'out_of_stock')
ORDER BY
  CASE estado WHEN 'out_of_stock' THEN 0 ELSE 1 END,
  cantidad ASC, nombre ASC
LIMIT 10
```

Prioriza visualmente lo más crítico: rojo (`out_of_stock`) primero, después amarillo (`low_stock`) ordenado por stock ascendente. Cada item muestra `#id` para que la dueña pueda buscarlo rápido en su sistema de proveedores.

### Conversión de divisas
`CurrencyConversionCard` consume **frankfurter.app** (API externa pública, sin API key) para convertir los ingresos en MXN a USD y EUR. Cubre el requisito de "integración de servicios externos" del Sprint 2.

## Pestaña Seguridad — fuente y fórmulas

Endpoint: `GET /api/analytics/security` ([backend/src/routes/analytics.js](../../backend/src/routes/analytics.js)). Todas las queries corren contra la tabla `audit_log`.

### Intentos de login (últimos 7 días)
| MetricCard | Fórmula |
|---|---|
| Total intentos | `COUNT(*) WHERE event_type='login_attempt'` |
| Exitosos | `SUM(success=1)` |
| Fallidos | `SUM(success=0)` |
| Tasa de éxito | `successful / total * 100%` (calculado en cliente) |

### Llamadas a la API (últimas 24 horas)
| MetricCard | Fórmula |
|---|---|
| Total | `COUNT(*) WHERE event_type='api_call'` |
| Exitosas | `status_code BETWEEN 200 AND 399` |
| No autorizadas | `status_code IN (401, 403)` |
| Errores 5xx | `status_code >= 500` |
| Latencia prom. | `AVG(duration_ms)` |

### Endpoints más usados (24h)
```sql
SELECT method, path, COUNT(*) AS hits
FROM audit_log
WHERE event_type='api_call' AND timestamp >= now-24h
GROUP BY method, path
ORDER BY hits DESC
LIMIT 5
```

### Logins fallidos recientes
```sql
SELECT timestamp, email, error_message, ip_address
FROM audit_log
WHERE event_type='login_attempt' AND success=0 AND timestamp >= now-7d
ORDER BY timestamp DESC
LIMIT 10
```

Muestra el email, el código de error de Firebase Auth (`wrong-password`, `user-not-found`, etc.) y la IP origen — útil para detectar patrones de ataque.

## Responsive

`LayoutBuilder` ajusta la grilla de `MetricCard` según ancho disponible:
- `>= 1100px`: 4 columnas
- `>= 720px`: 3 columnas
- resto: 2 columnas

Aplica tanto en la pestaña Negocio como en la de Seguridad.

## Tracking

Al montar la página se dispara:
```dart
AnalyticsService.instance.logScreen('analytics_dashboard');
```

Que en debug imprime:
```
[analytics] screen_viewed {screen_name: analytics_dashboard}
```

Y en release viaja a Firebase Analytics como evento `screen_viewed` con `screen_name=analytics_dashboard`. Además, `FirebaseAnalyticsObserver` registrado en `go_router` envía automáticamente un evento `screen_view` con la ruta correspondiente.

## Pruebas

| Test | Verifica |
|---|---|
| [`test/unit/analytics/analytics_repository_test.dart`](../../test/unit/analytics/analytics_repository_test.dart) — 3 tests | Parseo del DTO de `/api/analytics/dashboard` con `MockClient`: todos los campos, defaults para campos faltantes, propagación de errores. |
| [`backend/test/smoke.test.js`](../../backend/test/smoke.test.js) — 3 tests del sprint | `GET /api/analytics/security` agrega login_attempts y api_calls correctamente, `GET /api/analytics/dashboard` incluye `productsNeedingRestock`, `POST /api/security/login-attempt` es público. |
| [`test/e2e/analytics_dashboard_e2e_test.dart`](../../test/e2e/analytics_dashboard_e2e_test.dart) — 2 tests E2E | Flujo completo: loading → datos de negocio → cambio a Seguridad → reload + error 5xx (mockea HTTP, evita Firebase). |

## Cómo navegar

```sh
# Terminal 1: backend
cd backend && npm run dev

# Terminal 2: Flutter
flutter run
# Login → Sidebar → Analítica (o navegar a /analytics)
```

En el dashboard verás dos pestañas en la parte superior. La pestaña Negocio se carga primero; la de Seguridad ya estará lista cuando hagas tap.
