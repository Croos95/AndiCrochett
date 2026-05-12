# Sprint 4 — Pruebas y CI/CD

## Descripción del sprint
Sprint dedicado a montar una suite de **pruebas automatizadas** sobre el código existente y un **pipeline de CI** que las corra en cada push/PR a `main`. Cubre las cuatro dimensiones que pide el PDF: unitarias, de integración, E2E y pipeline.

## Objetivo
- Garantizar que el dominio (modelos, parser de patrones) y la capa de datos (SQLite) están cubiertos por pruebas determinísticas.
- Detectar regresiones antes de mergear cambios mediante GitHub Actions.
- Documentar cómo ejecutar cada categoría de prueba localmente.

## Tecnologías utilizadas
- `flutter_test` — runner unitario.
- `sqflite_common_ffi` ^2.3.0 — motor SQLite vía FFI para correr pruebas de BD reales en escritorio/CI sin emulador. (ffi significa "Foreign Function Interface", es decir, permite llamar a código nativo desde Dart).
- `integration_test` — runner E2E sobre el binding real de Flutter (escritorio o dispositivo).
- **GitHub Actions** + [subosito/flutter-action@v2](https://github.com/subosito/flutter-action) — pipeline CI.

## Estructura entregada
```
test/
├── unit/
│   ├── models/
│   │   ├── product_model_test.dart
│   │   ├── order_model_test.dart
│   │   └── user_model_test.dart
│   ├── parser/
│   │   └── pattern_parser_test.dart
│   ├── services/
│   │   └── analytics_service_test.dart   ← agregado en Sprint 5
│   └── analytics/
│       └── analytics_repository_test.dart ← agregado en Sprint 5
└── integration/
    └── database_helper_test.dart

integration_test/
└── app_smoke_test.dart

.github/workflows/
└── ci.yml
```

## Resultado de la última ejecución local
```
00:05 +55: All tests passed!
```
55 pruebas pasando en `flutter test test/ -j 1` (Windows + Dart SDK 3.9.2). Captura: [`capturas/`](capturas/).

Nota: el flag `-j 1` fuerza ejecución serial. Los tests de integración comparten el archivo `andicrochett.db` en el cwd del runner, así que correrlos en paralelo causa races entre isolates.

## Documentación detallada
1. [Pruebas unitarias](01-pruebas-unitarias.md)
2. [Pruebas de integración](02-pruebas-integracion.md)
3. [Pruebas E2E](03-pruebas-e2e.md)
4. [Pipeline CI/CD](04-pipeline-ci-cd.md)

## Instrucciones de ejecución
```sh
# Todas las pruebas no-E2E (unidad + integración) — serial
flutter test test/ -j 1

# Solo unitarias (pueden correr en paralelo, no tocan BD)
flutter test test/unit/models/ test/unit/parser/ test/unit/services/

# Solo integración (SQLite via FFI) — serial obligatorio
flutter test test/integration/ test/unit/analytics/ -j 1

# E2E (necesita un device / chrome)
flutter test integration_test/ -d chrome
```

## Criterios cumplidos
| Criterio del PDF | Entregado |
|---|---|
| Pruebas unitarias | 39 tests en `test/unit/` (modelos + parser + analytics service) |
| Pruebas de integración | 8 + 5 tests contra SQLite real (BD helper + analytics repository) |
| Pruebas E2E | 3 widget tests en `integration_test/` |
| Pipeline CI/CD | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) con jobs `flutter-test` + `functions-lint` |
