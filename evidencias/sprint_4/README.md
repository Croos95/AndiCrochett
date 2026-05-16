# Sprint 4 — Pruebas y CI/CD

## Descripción del sprint
Sprint dedicado a montar una suite de **pruebas automatizadas** sobre el código (cliente Flutter + backend Node) y un **pipeline de CI** que las corra en cada push/PR a `main`. Cubre las cuatro dimensiones que pide el PDF: unitarias, de integración, E2E y pipeline.

## Objetivo
- Garantizar que el dominio (modelos, parser de patrones), los servicios (`ApiClient`, `ExchangeRateService`), la capa de datos y las rutas del backend están cubiertas por pruebas determinísticas.
- Detectar regresiones antes de mergear cambios mediante GitHub Actions.
- Documentar cómo ejecutar cada categoría de prueba localmente.

## Tecnologías utilizadas
- **`flutter_test`** — runner unitario y de widgets.
- **`http/testing.dart`** (`MockClient`) — intercepta requests HTTP en tests sin red real.
- **`integration_test`** — runner E2E sobre el binding real de Flutter (requiere device).
- **`node:test`** (built-in en Node 20+) + **`supertest`** — runner del backend.
- **GitHub Actions** + [`subosito/flutter-action@v2`](https://github.com/subosito/flutter-action) — pipeline CI con 5 jobs en paralelo.

## Estructura entregada
```
test/                                  ← Flutter
├── unit/
│   ├── models/        (product, order, user)
│   ├── parser/        (pattern_parser_test)
│   ├── services/      (analytics_service, api_client, exchange_rate)
│   └── analytics/     (analytics_repository — MockClient)
└── e2e/
    └── analytics_dashboard_e2e_test.dart   ← E2E completo del dashboard

integration_test/
└── app_smoke_test.dart                ← E2E sobre device real (widget bindings)

backend/test/                          ← Node
└── smoke.test.js                      ← 12 tests con supertest

.github/workflows/ci.yml               ← 5 jobs
```

## Conteo de pruebas

| Categoría | Archivo | Tests |
|---|---|---|
| Unit — modelos | `test/unit/models/*` | 12 |
| Unit — parser | `test/unit/parser/pattern_parser_test.dart` | 19 |
| Unit — servicios | `test/unit/services/*` | 21 |
| Unit — analytics repo | `test/unit/analytics/analytics_repository_test.dart` | 3 |
| Unit — auth helper | `test/widget/auth_provider_test.dart` (si aplica) | — |
| E2E — dashboard | `test/e2e/analytics_dashboard_e2e_test.dart` | 2 |
| Widget E2E (device) | `integration_test/app_smoke_test.dart` | 3 |
| Backend | `backend/test/smoke.test.js` | 12 |
| **Total** | | **~72+** |

(Los conteos son orientativos; lo autoritativo es la salida de `flutter test` y `npm test` en local/CI.)

## Documentación detallada
1. [Pruebas unitarias](01-pruebas-unitarias.md)
2. [Pruebas de integración](02-pruebas-integracion.md)
3. [Pruebas E2E](03-pruebas-e2e.md)
4. [Pipeline CI/CD](04-pipeline-ci-cd.md)

## Instrucciones de ejecución

```sh
# Todas las pruebas Flutter (unit + e2e)
flutter test

# Solo unitarias
flutter test test/unit/

# Solo E2E del dashboard (sin device)
flutter test test/e2e/

# Widget E2E sobre device (requiere Android emulator o desktop habilitado)
flutter test integration_test/ -d <device>

# Backend
cd backend && npm test
```

## Criterios cumplidos
| Criterio del PDF | Entregado |
|---|---|
| Pruebas unitarias | Modelos + parser + servicios (`ApiClient`, `AnalyticsService`, `ExchangeRateService`, `AnalyticsRepository`) en `test/unit/` |
| Pruebas de integración | `backend/test/smoke.test.js` — 12 tests con supertest contra rutas reales del backend + SQLite |
| Pruebas E2E | `test/e2e/analytics_dashboard_e2e_test.dart` — flujo completo loading → tab Negocio → tab Seguridad → reload, con `MockClient`. Plus `integration_test/app_smoke_test.dart` para device-bound |
| Pipeline CI/CD | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) con 5 jobs (Flutter analyze+test, backend test, build Android, build Web, Cloud Functions legadas) |
