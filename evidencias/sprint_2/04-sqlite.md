# Sprint 2 · SQLite — estado actual

La capa SQLite ya existía cuando arrancó el sprint. Este documento la resume y la liga a las pruebas que la validan.

## Implementación
[`lib/database_helper.dart`](../../lib/database_helper.dart) — singleton de ~930 líneas con:
- Definición de 8 tablas.
- 9 migraciones (v1 → v9) con `_onUpgrade`.
- CRUD genérico (`insert`, `queryAll`, `update`, `delete`) + métodos específicos por entidad.
- Transacciones para operaciones compuestas (`createOrderFull`, `cancelAndReturnStock`).

## Tablas

| Tabla | Para qué | Modelo Dart |
|---|---|---|
| `usuarios` | Perfil sincronizado con Firebase Auth + settings JSON | `UserModel` |
| `productos` | Inventario, stock, estado | `ProductModel` |
| `clientes` | Contactos para pedidos | (sin modelo, Map directo) |
| `pedidos` | Cabecera de cada pedido | `OrderModel` |
| `items_pedido` | Líneas de pedido | `OrderItem` |
| `designs` | Diseños de crochet | `DesignModel` |
| `patterns` | Patrones tipados por diseño | `PatternModel` |
| `catalog_settings` | Config del catálogo público por usuario | (Map directo) |

## Transacciones críticas
`createOrderFull(OrderModel order)` (línea ~460):
1. Inserta la cabecera en `pedidos`.
2. Inserta cada `OrderItem` en `items_pedido`.
3. Descuenta `cantidad` de cada producto en `productos`.

Todo dentro de una única `db.transaction()`. Si cualquier paso falla, los anteriores hacen rollback automático — no quedan pedidos sin items ni stock fantasma.

`cancelAndReturnStock(int orderId)` hace la operación inversa: lee los items, devuelve la cantidad al stock, borra el pedido.

## Migraciones
La versión actual es **9**. El esquema crece de forma backward-compatible:

| v | Cambio | Por qué |
|---|---|---|
| 2 | Agregar columnas a `productos` (categoría, color, peso, marca…) | Catálogo enriquecido |
| 3 | Crear `usuarios` | Persistir perfil tras login |
| 4 | `usuarios.settings`, `pedidos.items_json` | Preferencias + snapshot legacy |
| 5 | `pedidos.usuario_id`, `pedidos.fecha_entrega`, etc. | Pedidos asociados a usuario y con fecha de entrega |
| 6 | Crear `designs` | Feature de diseños |
| 7 | Crear `patterns` | Feature de patrones (Sprint posterior) |
| 8 | Crear `catalog_settings` | Catálogo público |
| 9 | `pedidos.nombre_cliente` desnormalizado | Performance — evitar JOIN en cada listado |

Cada migración está envuelta en `try/catch` porque `ALTER TABLE` no es idempotente en SQLite — si la columna ya existe, falla pero no afecta a otras migraciones.

## Pruebas (Sprint 4)
[`test/integration/database_helper_test.dart`](../../test/integration/database_helper_test.dart):

| Grupo | Tests |
|---|---|
| Productos (CRUD) | add + getAll, updateProductQuantity, deleteProduct, searchProducts |
| Clientes (CRUD) | add + getAll, updateClient parcial |
| Schema | Versión de BD es 9 |

Se corren con `sqflite_common_ffi` contra SQLite real en CI — ver [Sprint 4 · 02-pruebas-integracion.md](../sprint_4/02-pruebas-integracion.md).

## SQLite + cloud — cómo conviven hoy
- **SQLite** es la fuente de verdad **local** (pedidos, productos, etc.).
- **Firebase Auth** maneja identidad.
- **Firestore** está provisionado pero no sincronizado todavía (los `firestore.rules` ya validan los esquemas si decidimos hacerlo).

La idea es offline-first: el dueño del negocio puede crear pedidos sin conexión y, en un sprint futuro, sincronizar a Firestore cuando vuelva la red.

## Cómo inspeccionar la BD localmente
```sh
# Windows — encontrar el archivo
%LOCALAPPDATA%\com.example.andicrochett\andicrochett.db

# Inspeccionar con sqlite3
sqlite3 andicrochett.db
sqlite> .tables
sqlite> SELECT * FROM productos LIMIT 5;
```
