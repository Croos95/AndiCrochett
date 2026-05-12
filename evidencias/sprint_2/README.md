# Sprint 2 — Conexiones / Flutter

## Descripción del sprint
La app **AndiCrochett** ya era multiplataforma Flutter y persistía en SQLite cuando arrancó este sprint. El cierre del Sprint 2 agrega lo que faltaba según el PDF: **consumo de una API REST externa con manejo de JSON** y **una segunda integración de servicio externo** visible en la UI.

## Objetivo
- Demostrar consumo real de una API REST pública (no mock).
- Mostrar el ciclo completo: request → JSON → DTO → render en UI.
- Dejar el cliente testeado con `MockClient` para que CI lo valide sin pegarle a la red.

## Tecnologías utilizadas
- **`http`** package en Dart — cliente HTTP idiomatico, soporta web y móvil.
- **`api.frankfurter.app`** — API pública del Banco Central Europeo, sin API key, devuelve tipos de cambio en JSON.
- **`http/testing`** (`MockClient`) — para tests sin red.

## Estado anterior vs. ahora

| Punto del PDF | Antes | Ahora |
|---|---|---|
| Aplicación multiplataforma Flutter | ✓ Web/Android/iOS/Desktop | ✓ Sin cambios |
| Uso de SQLite | ✓ `database_helper.dart` con 8 tablas | ✓ + tests de integración (Sprint 4) |
| Consumo de API REST | ✗ (solo `/api/health` interno) | ✓ `ExchangeRateService` consume frankfurter.app |
| Manejo de JSON | ✓ Parcial (SQLite Map) | ✓ + `ExchangeRate.fromJson` + manejo de errores |
| Integración de servicios externos | ✓ Firebase Auth + Firestore | ✓ + frankfurter.app + (vía Sprint 3) `/api/secure/*` propio |

## Estructura entregada
```
lib/core/services/
├── exchange_rate_service.dart       ← cliente REST externo
└── secure_api_client.dart           ← (Sprint 3) cliente para API propia

lib/features/analytics/presentation/widgets/
└── currency_conversion_card.dart    ← muestra los rates en el dashboard

test/unit/services/
└── exchange_rate_service_test.dart  ← 7 tests con MockClient
```

## Cómo verlo
```sh
flutter run -d chrome
# Login → ir a /analytics → tarjeta "Conversión de ingresos (API externa)"
```
La tarjeta hace `GET https://api.frankfurter.app/latest?from=MXN&to=USD,EUR` al montarse, parsea el JSON y muestra el equivalente del ingreso de 30 días en USD y EUR.

## Pruebas
```sh
flutter test test/unit/services/exchange_rate_service_test.dart
```
Salida:
```
+7: All tests passed!
```
Tests con `MockClient` — no tocan red, corren en CI.

## Documentación detallada
1. [Consumo de API REST](01-api-rest-externa.md)
2. [Manejo de JSON](02-manejo-json.md)
3. [Integración de servicios externos](03-servicios-externos.md)
4. [SQLite (estado actual)](04-sqlite.md)

## Criterios cumplidos
| Criterio del PDF | Entregado |
|---|---|
| Aplicación multiplataforma Flutter | App existente, sin cambios — corre en web/Android/iOS/Windows |
| Uso de SQLite | `database_helper.dart` con CRUD + transacciones + 9 migraciones |
| Consumo de API REST | `ExchangeRateService` consume frankfurter.app con error handling |
| Manejo de JSON | `ExchangeRate.fromJson` + `OrderModel.fromMap` + `UserSettings` serializado como JSON en columna |
| Integración de servicios externos | frankfurter.app + Firebase Auth + Firestore + Cloud Functions |
