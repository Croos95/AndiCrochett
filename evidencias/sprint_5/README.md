# Sprint 5 — Analítica

## Descripción del sprint
Sprint dedicado a montar la **capa de eventos** del producto, el **dashboard analítico** y la **infraestructura para integrar Firebase Analytics**. Cubre los cuatro puntos del PDF: Eventos (Data Layer), Integración Analytics, Dashboard y Análisis de resultados.

## Objetivo
- Centralizar los eventos del negocio en una taxonomía estable y tipada.
- Exponer un dashboard que aprovecha los datos locales (SQLite) para tomar decisiones — productos sin stock, ingresos recientes, top productos vendidos, distribución de pedidos por estado.
- Dejar el cableado documentado para conectar Firebase Analytics en producción sin tocar call sites.

## Tecnologías utilizadas
- **AnalyticsService** propio sobre el patrón de sinks pluggables.
- **SQLite** (vía `DatabaseHelper`) como fuente de verdad para las métricas.
- **Flutter** + `go_router` para la ruta `/analytics`.
- Stubs de integración para `firebase_analytics` (sin agregar el package — ver [02-integracion-analytics.md](02-integracion-analytics.md)).

## Estructura entregada
```
lib/core/services/
└── analytics_service.dart                ← Data Layer + sinks

lib/features/analytics/
├── data/
│   ├── analytics_repository.dart         ← Agregaciones SQL
│   └── models/dashboard_metrics.dart     ← DTO inmutable
└── presentation/
    ├── pages/
    │   └── analytics_dashboard_page.dart ← Página principal
    └── widgets/
        ├── metric_card.dart
        └── status_breakdown_bar.dart     ← Gráfica sin libs externas

test/unit/services/analytics_service_test.dart
test/unit/analytics/analytics_repository_test.dart
```

## Documentación detallada
1. [Eventos (Data Layer)](01-eventos-data-layer.md)
2. [Integración Analytics](02-integracion-analytics.md)
3. [Dashboard](03-dashboard.md)
4. [Análisis de resultados](04-analisis-resultados.md)

## Cómo verlo localmente
```sh
flutter run -d chrome
# Login → navegar a /analytics
```
La ruta `/analytics` está registrada en [`lib/core/config/routes.dart`](../../lib/core/config/routes.dart).

## Pruebas asociadas
- `test/unit/services/analytics_service_test.dart` — 8 tests sobre la taxonomía y el fan-out de sinks.
- `test/unit/analytics/analytics_repository_test.dart` — 5 tests de agregaciones contra SQLite real (FFI).

Resultado:
```
+55: All tests passed!
```

## Criterios cumplidos
| Criterio del PDF | Entregado |
|---|---|
| Eventos (Data Layer) | [`AnalyticsService`](../../lib/core/services/analytics_service.dart) con 14 eventos catalogados + helpers tipados |
| Integración Analytics | `FirebaseAnalyticsSink` stub documentado + wiring de un evento real en `InventoryRepository.createProduct` |
| Dashboard | [`/analytics`](../../lib/features/analytics/presentation/pages/analytics_dashboard_page.dart) con 6 KPIs + gráfico de pedidos + top productos |
| Análisis de resultados | [04-analisis-resultados.md](04-analisis-resultados.md) describe cómo leer cada métrica y qué decisión dispara |
