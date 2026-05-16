# Sprint 5 — Analítica

## Descripción del sprint
Sprint dedicado a montar la **capa de eventos** del producto, el **dashboard analítico de dos dimensiones** (negocio + ciberseguridad) y la **integración real con Firebase Analytics**. Cubre los cuatro puntos del PDF: Eventos (Data Layer), Integración Analytics, Dashboard y Análisis de resultados.

## Objetivo
- Centralizar los eventos del negocio en una taxonomía estable y tipada.
- Exponer un dashboard que aprovecha los datos centralizados (SQLite en el backend) para tomar decisiones — productos sin stock, ingresos recientes, top productos vendidos, distribución de pedidos por estado, productos por reabastecer.
- Agregar una segunda dimensión de analítica, **ciberseguridad**: intentos de login, llamadas a la API, endpoints más usados, logins fallidos recientes.
- Enviar cada evento del Data Layer a **Firebase Analytics** real (no stub).

## Tecnologías utilizadas
- **AnalyticsService** propio sobre el patrón de sinks pluggables (Console + Firebase + InMemory para tests).
- **Firebase Analytics** (`firebase_analytics: ^10.10.7`) — sink real, `FirebaseAnalyticsObserver` para screen tracking automático en `go_router`.
- **Backend Node + SQLite** como fuente de verdad de las métricas (queries SQL agregadas en `backend/src/routes/analytics.js`).
- **Tabla `audit_log`** (nueva) — bitácora de cada request HTTP + cada intento de login, alimenta la sección Seguridad.
- **Flutter** + `go_router` para la ruta `/analytics`.

## Estructura entregada
```
lib/core/services/
├── analytics_service.dart                ← Data Layer + sinks (Console + Firebase real)
└── security_reporter.dart                ← Reporta intentos de login al backend

lib/features/analytics/
├── data/
│   ├── analytics_repository.dart         ← loadDashboard() + loadSecurity()
│   └── models/dashboard_metrics.dart     ← DashboardMetrics + SecurityMetrics
└── presentation/
    ├── pages/
    │   └── analytics_dashboard_page.dart ← 2 pestañas: Negocio + Seguridad
    └── widgets/
        ├── metric_card.dart
        └── status_breakdown_bar.dart

backend/src/
├── middleware/audit.js                   ← persiste cada request en audit_log
├── routes/analytics.js                   ← /dashboard + /security
└── routes/security.js                    ← POST /login-attempt (público)

test/
├── unit/services/analytics_service_test.dart
├── unit/services/api_client_test.dart
├── unit/analytics/analytics_repository_test.dart   ← MockClient
└── e2e/analytics_dashboard_e2e_test.dart           ← flujo completo
```

## Documentación detallada
1. [Eventos (Data Layer)](01-eventos-data-layer.md)
2. [Integración Analytics](02-integracion-analytics.md)
3. [Dashboard](03-dashboard.md)
4. [Análisis de resultados](04-analisis-resultados.md)

## Cómo verlo localmente
```sh
# Backend
cd backend && npm run dev          # o npm run dev:https

# Flutter
flutter run                         # autodetecta plataforma (Android usa 10.0.2.2)
# Login → desde el sidebar → "Analítica"
```
La ruta `/analytics` está registrada en [`lib/core/config/routes.dart`](../../lib/core/config/routes.dart).

## Pruebas asociadas
- [`test/unit/services/analytics_service_test.dart`](../../test/unit/services/analytics_service_test.dart) — **7 tests** sobre la taxonomía y el fan-out de sinks.
- [`test/unit/analytics/analytics_repository_test.dart`](../../test/unit/analytics/analytics_repository_test.dart) — **3 tests** del parseo del DTO usando `MockClient`.
- [`test/unit/services/api_client_test.dart`](../../test/unit/services/api_client_test.dart) — **7 tests** del cliente HTTP que alimenta el repositorio.
- [`test/e2e/analytics_dashboard_e2e_test.dart`](../../test/e2e/analytics_dashboard_e2e_test.dart) — **2 tests E2E** del dashboard completo (loading → datos negocio → tab seguridad → reload + error 5xx).
- [`backend/test/smoke.test.js`](../../backend/test/smoke.test.js) — 3 tests específicos del sprint: `/api/analytics/security`, `/api/analytics/dashboard` con `productsNeedingRestock`, `/api/security/login-attempt`.

## Criterios cumplidos
| Criterio del PDF | Entregado |
|---|---|
| Eventos (Data Layer) | [`AnalyticsService`](../../lib/core/services/analytics_service.dart) con 14 eventos catalogados + helpers tipados |
| Integración Analytics | `FirebaseAnalyticsSink` **real**, configurado en [`main.dart`](../../lib/main.dart). `FirebaseAnalyticsObserver` registra screen views automáticas. `setUserId` se sincroniza con `FirebaseAuth.userChanges()`. Wiring real ya en `inventory_repository.dart` (productCreated) y `auth_provider.dart` (loginSuccess/Failed) |
| Dashboard | [`/analytics`](../../lib/features/analytics/presentation/pages/analytics_dashboard_page.dart) con **2 pestañas**: <br>• **Negocio** — 6 KPIs + conversión de divisas + pedidos por estado + top productos vendidos + productos por reabastecer <br>• **Seguridad** — login attempts (7d) + API calls (24h) + endpoints más usados + logins fallidos recientes |
| Análisis de resultados | [04-analisis-resultados.md](04-analisis-resultados.md) describe cómo leer cada métrica (negocio + seguridad) y qué decisión dispara |
