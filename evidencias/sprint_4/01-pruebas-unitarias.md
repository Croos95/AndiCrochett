# Sprint 4 · Pruebas unitarias

Las pruebas unitarias viven en [`test/unit/`](../../test/unit/) y cubren **lógica de dominio pura**: modelos serializables y el parser de patrones de crochet. No tocan red, base de datos ni UI, así que se ejecutan en milisegundos y son 100% determinísticas.

## Cobertura

### Modelos (`test/unit/models/`)
| Archivo | Qué prueba |
|---|---|
| [`product_model_test.dart`](../../test/unit/models/product_model_test.dart) | Enum `ProductStatus`, round-trip `toMap`/`fromMap`, `copyWith` parcial, tolerancia a maps incompletos |
| [`order_model_test.dart`](../../test/unit/models/order_model_test.dart) | Subtotal de `OrderItem`, labels en español, serialización del `OrderModel`, items pasados aparte |
| [`user_model_test.dart`](../../test/unit/models/user_model_test.dart) | `UserSettings` con notifications `int↔bool`, codificación JSON dentro de la columna `settings`, igualdad por `uid`+`email` |

### Parser de patrones (`test/unit/parser/`)
[`pattern_parser_test.dart`](../../test/unit/parser/pattern_parser_test.dart) divide los casos en tres grupos:

- **Casos válidos**: `R1: 6pb`, omitir quantity (`pb` ≡ `1pb`), múltiples elementos con coma, bloques `[..]xN`, sufijo `(total)` opcional, marcadores `r/v` minúsculos, `X` mayúscula.
- **Errores de sintaxis**: línea vacía, marcador inválido, falta número de vuelta, falta `:`, bloques anidados, bloque sin multiplicador, cantidad sin código.
- **`parseAll`**: ignora comentarios `#` y líneas vacías, recolecta errores sin abortar, preserva `sourceLineIndex` original (clave para que el editor resalte la línea correcta).

## Total
**31 tests** unitarios en 4 archivos.

## Por qué importan
- El **parser** es el corazón del feature de patrones. Cada regla de gramática está cubierta por al menos un test, así que cambios futuros al parser tienen una red de seguridad inmediata.
- Los **modelos** son la frontera con SQLite: si `toMap` rompe el contrato (clave `precio` vs `price`), la BD truena en producción. Las pruebas garantizan que las claves SQL no cambien por accidente.

## Cómo ejecutarlas
```sh
flutter test test/unit/
```

Salida esperada (resumen) osea que todas las pruebas pasen:
```
00:00 +31: All tests passed!
```
