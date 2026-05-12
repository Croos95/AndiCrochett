# Sprint 4 · Pruebas de integración

Las pruebas de integración viven en [`test/integration/`](../../test/integration/) y verifican que la **capa de datos** (`DatabaseHelper`) funciona contra un motor SQLite **real**, no contra mocks. Se ejecutan en el runner de tests gracias a `sqflite_common_ffi`, que carga el binario nativo de SQLite vía FFI — no se necesita emulador.

## Por qué SQLite real y no mocks
Un mock acepta cualquier SQL que le pasemos; SQLite real rechaza columnas con tipo incorrecto, foreign keys mal escritas o tablas inexistentes. Como `DatabaseHelper` mezcla CREATE TABLE, transacciones (`createOrderFull`), JOINs y `ALTER TABLE` en migraciones, mockear escondería bugs reales. Estas pruebas atrapan:

- Tablas/columnas mal nombradas.
- Migraciones con SQL inválido.
- Queries con `JOIN` que rompen al actualizar columnas.

## Cobertura

[`database_helper_test.dart`](../../test/integration/database_helper_test.dart):

| Grupo | Tests |
|---|---|
| **Productos (CRUD)** | `addProduct` + `getAllProducts`, `updateProductQuantity`, `deleteProduct`, `searchProducts` con LIKE |
| **Clientes (CRUD)** | `addClient` + `getAllClients`, `updateClient` parcial (solo modifica campos pasados) |
| **Schema** | Verifica que `_databaseVersion = 9` se aplica al abrir la BD |

**Total: 8 tests de integración.**

## Aislamiento entre tests
```dart
setUp(() async {
  await DatabaseHelper.instance.closeDatabase();
  final dbPath = p.join(await getDatabasesPath(), 'andicrochett.db');
  final f = File(dbPath);
  if (await f.exists()) await f.delete();
});
```
Cada test arranca con BD vacía. El singleton se cierra y el archivo se elimina antes y después.

## Cómo ejecutarlas
```sh
flutter test test/integration/
```

Salida esperada:
```
+8: All tests passed!
```

## Notas
- `sqflite_common_ffi` está en `dev_dependencies` de [`pubspec.yaml`](../../pubspec.yaml).
- Las pruebas crean un archivo `andicrochett.db` temporal en el cwd del test runner. `tearDownAll` lo limpia.
- En CI corren en Ubuntu sin problema: el binario nativo de SQLite se compila automáticamente.
