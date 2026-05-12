# Sprint 5 · Dashboard

La página vive en [`/analytics`](../../lib/features/analytics/presentation/pages/analytics_dashboard_page.dart) y es accesible vía `go_router` (ruta registrada en [`routes.dart`](../../lib/core/config/routes.dart)). Carga métricas con un único `Future` y se reorganiza responsivamente.

## Composición

```
AnalyticsDashboardPage
├── AppBar — título + botón "Recargar"
└── FutureBuilder<DashboardMetrics>
    └── _DashboardBody
        ├── Sección "Resumen" — 6 MetricCard en grid responsivo
        ├── Sección "Pedidos por estado" — StatusBreakdownBar
        └── Sección "Top productos vendidos" — ListTile · 5 items
```

## Métricas mostradas

| MetricCard | Fórmula SQL | Acción que dispara |
|---|---|---|
| Productos | `SELECT COUNT(*) FROM productos` | Crecimiento del catálogo |
| Bajo stock | `WHERE estado = 'low_stock'` | Reabastecer pronto |
| Sin existencias | `WHERE estado = 'out_of_stock'` | Reabastecer YA |
| Pedidos totales | `SELECT COUNT(*) FROM pedidos` | Volumen histórico |
| Clientes | `SELECT COUNT(*) FROM clientes` | Tamaño de la base |
| Ingresos 30 días | `SUM(total) WHERE estado='completed' AND fecha_pedido >= now-30d` | Salud financiera reciente |

### Pedidos por estado
Una barra horizontal proporcional + leyenda. Colores fijos por estado:

- **Amarillo** — pending
- **Azul** — inProgress
- **Verde** — completed
- **Rojo** — cancelled

Implementación: `Row` con `Expanded(flex: count)`. Sin librerías de charts — mantenerlo simple evita romper builds web por incompatibilidades de canvas.

### Top productos
`SELECT nombre_producto, SUM(cantidad), SUM(cantidad * precio_unitario) FROM items_pedido GROUP BY nombre_producto ORDER BY units DESC LIMIT 5`. Da unidades vendidas y revenue por producto.

## Responsive
`LayoutBuilder` ajusta la grilla:
- `>= 1100px`: 4 columnas
- `>= 720px`: 3 columnas
- resto: 2 columnas

El móvil entonces ve 3 filas de 2 cards; el desktop ve 1.5 filas de 4 cards.

## Tracking
Al montar la página se dispara:
```dart
AnalyticsService.instance.logScreen('analytics_dashboard');
```

Lo cual emite por consola en debug:
```
[analytics] screen_viewed {screen_name: analytics_dashboard}
```

## Pruebas
[`test/unit/analytics/analytics_repository_test.dart`](../../test/unit/analytics/analytics_repository_test.dart):

| Test | Verifica |
|---|---|
| reporta ceros cuando la BD está vacía | DTO con valores default |
| cuenta productos por estado correctamente | filtros `low_stock`/`out_of_stock` |
| agrega ingresos solo de pedidos completados recientes | filtro doble: estado + ventana 30d |
| agrupa pedidos por estado y los devuelve ordenados | `GROUP BY` + `ORDER BY count DESC` |
| top productos respeta unidades vendidas | join lógico con `items_pedido` |

**5 tests pasando** contra SQLite real (FFI).

## Cómo navegar
1. `flutter run -d chrome`
2. Login con cuenta válida
3. En la URL: `http://localhost:5000/#/analytics`

(En el futuro: agregar entry del sidebar en `DashboardPage` para acceso sin URL directa.)
