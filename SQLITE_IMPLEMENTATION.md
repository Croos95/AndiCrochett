# SQLite Implementation Summary

## ✅ Problemas Corregidos

### 1. **Base de Datos Actualizada**
- ✅ Versión de BD actualizada a v2
- ✅ Migración automática de v1 a v2 con ALTER TABLE
- ✅ Tabla de productos completamente integrada con ProductModel

### 2. **Campos Faltantes en Productos**
Agregados a la tabla `productos`:
- `categoria` (TEXT)
- `color` (TEXT)
- `peso` (TEXT)
- `marca` (TEXT)
- `cantidad` (INTEGER) - replaza tabla inventario
- `estado` (TEXT) - productStatus
- `fecha_actualizacion` (TIMESTAMP)

### 3. **Nueva Tabla: Items de Pedidos**
Tabla `items_pedido` para relaciones muchos-a-muchos:
- `id` (INTEGER PRIMARY KEY)
- `pedido_id` (INTEGER, FK)
- `producto_id` (INTEGER, FK)
- `nombre_producto` (TEXT)
- `cantidad` (INTEGER)
- `precio_unitario` (REAL)

### 4. **Eliminación de Tabla de Inventario**
La gestión de stock ahora se hace directamente en la tabla `productos`.

### 5. **Mejoras en DatabaseHelper**
Nuevos métodos:
- `addProduct(Map)` - Acepta el toMap() del ProductModel
- `getProductById(int)` - Obtiene un producto por ID
- `searchProducts(String)` - Busca por nombre, descripción, categoría
- `getProductsByCategory(String)` - Filtra por categoría
- `addOrderItem()` - Agrega ítems a los pedidos
- `getOrderItems(int)` - Obtiene ítems de un pedido
- `deleteOrderItem()` - Elimina ítems
- `updateProductQuantity()` - Actualiza stock
- `incrementProductQuantity()` - Suma al stock
- `decrementProductQuantity()` - Resta del stock

### 6. **Nuevos Modelos Optimizados para SQLite**
- ✅ **ClientModel** (`lib/features/clients/data/models/client_model.dart`)
  - Métodos toMap() y fromMap()
  - Compatible con SQLite
  
- ✅ **OrderModel Mejorado** 
  - Compatible con Firestore Y SQLite
  - Campos duplicados para ambas BD
  - Método toFirestoreMap() para Firestore
  - Método toMap() para SQLite

### 7. **Nuevos Repositorios**
- ✅ **ClientRepository** - CRUD de clientes
  - createClient()
  - updateClient()
  - deleteClient()
  - getAllClients()
  - getClientById()
  - searchClients()

- ✅ **OrderRepository** - CRUD de pedidos
  - createOrder()
  - getAllOrders()
  - getOrdersByClient()
  - getOrdersByStatus()
  - updateOrderStatus()
  - deleteOrder()
  - addOrderItem()
  - getOrderItems()

### 8. **Mejoras en InventoryRepository**
- ✅ Métodos actualizados para usar ProductModel.toMap()
- ✅ Nuevo método watchByUser() para sincronización
- ✅ Métodos de búsqueda: searchProducts(), getProductsByCategory()

### 9. **Correcciones de Errores**
- ✅ Eliminadas referencias a updateInventoryQuantity()
- ✅ Actualizados métodos de addProduct para usar Map
- ✅ Corregidos null checks en agenda_page para dueDate
- ✅ Arreglada compatibilidad con OrderModel string ID vs int ID

## 📊 Esquema de Tablas Actualizado

```sql
-- Productos (completamente actualizada)
CREATE TABLE productos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL UNIQUE,
  descripcion TEXT DEFAULT '',
  precio REAL NOT NULL,
  imagen TEXT DEFAULT '',
  categoria TEXT DEFAULT '',
  color TEXT DEFAULT '',
  peso TEXT DEFAULT '',
  marca TEXT DEFAULT '',
  cantidad INTEGER DEFAULT 0,
  estado TEXT DEFAULT 'available',
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)

-- Clientes
CREATE TABLE clientes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  email TEXT UNIQUE,
  telefono TEXT,
  direccion TEXT
)

-- Pedidos
CREATE TABLE pedidos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cliente_id INTEGER NOT NULL,
  fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  total REAL NOT NULL,
  estado TEXT DEFAULT 'pending',
  FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
)

-- Items de Pedidos (NUEVO)
CREATE TABLE items_pedido (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pedido_id INTEGER NOT NULL,
  producto_id INTEGER NOT NULL,
  nombre_producto TEXT NOT NULL,
  cantidad INTEGER NOT NULL,
  precio_unitario REAL NOT NULL,
  FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  FOREIGN KEY (producto_id) REFERENCES productos(id)
)
```

## 🔄 Cómo Usar

### Crear un Producto
```dart
final product = ProductModel(
  name: 'Manta de Crochet',
  price: 50.0,
  currentStock: 10,
  category: 'Mantas',
  color: 'Azul',
  weight: '500g',
  brand: 'AndiCrochet',
);

final id = await inventoryRepo.createProduct(product);
```

### Crear un Pedido con Items
```dart
// 1. Crear el pedido
final orderId = await orderRepo.createOrder(OrderModel(
  clientId: 1,
  totalPrice: 150.0,
  status: OrderStatus.pending,
  createdAt: DateTime.now(),
));

// 2. Agregar ítems al pedido
await orderRepo.addOrderItem(
  orderId, 
  productId: 1,
  productName: 'Manta de Crochet',
  quantity: 2,
  unitPrice: 50.0,
);

// 3. Obtener ítems
final items = await orderRepo.getOrderItems(orderId);
```

### Actualizar Stock
```dart
await inventoryRepo.adjustStock(productId, -2); // Restar 2 unidades
await inventoryRepo.updateProductStock(productId, 5); // Fijar a 5
```

## ⚠️ Notas Importantes

1. **Migración**: Si ya tienes datos, la migración en `_onUpgrade()` agregará los campos faltantes automáticamente.

2. **Compatibilidad Dual**: El OrderModel mantiene compatibilidad con Firestore y SQLite. Usa:
   - `toMap()` para SQLite
   - `toFirestoreMap()` para Firestore
   - `fromMap()` para leer de SQLite
   - `fromDoc()` para leer de Firestore

3. **Stock en Productos**: El stock ya no está en una tabla separada, está en `cantidad` de la tabla `productos`.

4. **Cascada de Eliminación**: Al eliminar un pedido, sus ítems se eliminan automáticamente gracias a ON DELETE CASCADE.

5. **IDs**: 
   - SQLite usa INTEGER (int)
   - Firestore usa STRING (String)
   - El OrderModel maneja ambos casos

## 📝 Próximos Pasos Sugeridos

1. Crear sincronización bidireccional Firebase ↔ SQLite
2. Implementar búsqueda full-text optimizada
3. Agregar índices en las columnas de búsqueda frecuente
4. Crear backups automáticos de la BD local
5. Implementar validaciones de integridad referencial
