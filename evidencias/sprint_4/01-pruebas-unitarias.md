# Sprint 4 · Pruebas unitarias

Las pruebas unitarias viven en [`test/unit/`](../../test/unit/) y cubren **lógica pura**: modelos, parser, servicios. No tocan red real, base de datos local ni UI, así que se ejecutan en milisegundos y son 100% determinísticas.

## Cobertura

### Modelos (`test/unit/models/`)

| Archivo | Qué prueba |
|---|---|
| [`product_model_test.dart`](../../test/unit/models/product_model_test.dart) | Enum `ProductStatus`, round-trip `toMap`/`fromMap`, `copyWith` parcial, tolerancia a maps incompletos |
| [`order_model_test.dart`](../../test/unit/models/order_model_test.dart) | Subtotal de `OrderItem`, labels en español, serialización del `OrderModel`, items pasados aparte |
| [`user_model_test.dart`](../../test/unit/models/user_model_test.dart) | `UserSettings` con notifications `int↔bool`, codificación JSON de la columna `settings`, igualdad por `uid`+`email` |

### Parser de patrones (`test/unit/parser/`)

[`pattern_parser_test.dart`](../../test/unit/parser/pattern_parser_test.dart) divide los casos en tres grupos:

- **Casos válidos**: `R1: 6pb`, omitir quantity (`pb` ≡ `1pb`), múltiples elementos con coma, bloques `[..]xN`, sufijo `(total)` opcional, marcadores `r/v` minúsculos, `X` mayúscula.
- **Errores de sintaxis**: línea vacía, marcador inválido, falta número de vuelta, falta `:`, bloques anidados, bloque sin multiplicador, cantidad sin código.
- **`parseAll`**: ignora comentarios `#` y líneas vacías, recolecta errores sin abortar, preserva `sourceLineIndex` original (clave para que el editor resalte la línea correcta).

### Servicios (`test/unit/services/`)

| Archivo | Qué prueba |
|---|---|
| [`analytics_service_test.dart`](../../test/unit/services/analytics_service_test.dart) | Nombres snake_case estables, fan-out a múltiples sinks, helpers tipados (`logProductCreated`, `logLogin`, etc.), un sink que lanza no detiene a los demás |
| [`api_client_test.dart`](../../test/unit/services/api_client_test.dart) | Auth header `Bearer <token>`, query params serializados, body JSON, parseo de respuestas, manejo de errores 4xx (`{error: "..."}` y `{errors: [...]}`), propagación de errores del token provider |
| [`exchange_rate_service_test.dart`](../../test/unit/services/exchange_rate_service_test.dart) | Parseo de `ExchangeRate`, `convert` lanza si la moneda no está, manejo de 5xx, rechazo de JSON inválido |

### Repositorio de Analytics (`test/unit/analytics/`)

[`analytics_repository_test.dart`](../../test/unit/analytics/analytics_repository_test.dart): usa `MockClient` para inyectar respuestas JSON de `/api/analytics/dashboard`. Verifica que todos los campos del DTO se parsean, que defaults aplican cuando faltan campos, y que los errores HTTP se propagan como `ApiException`.

## Por qué importan

- El **parser** es el corazón del feature de patrones. Cada regla de gramática está cubierta por al menos un test, así que cambios futuros tienen una red de seguridad inmediata.
- Los **modelos** son la frontera con SQLite/JSON: si `toMap` rompe el contrato (clave `precio` vs `price`), el backend rechaza o devuelve campos vacíos. Las pruebas garantizan que las claves no cambien por accidente.
- El **`ApiClient`** es el único canal de salida de la app hacia el backend; un bug ahí afecta a 7 repositorios. Por eso tiene su propia batería de tests.

## Cómo ejecutarlas

```sh
flutter test test/unit/
```

Salida esperada (resumen) — todas las pruebas pasan:
```
00:00 +XX: All tests passed!
```

El número exacto crece a medida que se agregan tests; la última corrida del sprint reporta ~55 tests unitarios.
