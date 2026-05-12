import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';
import 'package:andicrochett/features/designs/data/models/design_model.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
//lib/database_helper.dart
class DatabaseHelper {
  // Configuración de la base de datos
  static const _databaseName = "andicrochett.db";
  static const _databaseVersion = 8;
  
  // Nueva columna para preferencias de usuario
  static const userSettings = 'settings'; 

  // Nueva columna para guardar ítems como JSON 
  static const orderItemsJson = 'items_json';

  // ============ TABLAS ============
  static const tableUsers = 'usuarios';
  static const tableProducts = 'productos';
  static const tableOrders = 'pedidos';
  static const tableOrderItems = 'items_pedido';
  static const tableClients = 'clientes';
  static const tableDesigns = 'designs';
  static const tablePatterns = 'patterns';
  static const tableCatalogSettings = 'catalog_settings';

  // ============ COLUMNAS - USUARIOS ============
  static const userId = 'id';
  static const userUid = 'uid';
  static const userEmail = 'email';
  static const userDisplayName = 'display_name';
  static const userPhotoUrl = 'photo_url';
  static const userAuthProvider = 'auth_provider';
  static const userCreatedAt = 'fecha_creacion';
  static const userUpdatedAt = 'fecha_actualizacion';

  // ============ COLUMNAS - PRODUCTOS ============
  static const productId = 'id';
  static const productName = 'nombre';
  static const productDescription = 'descripcion';
  static const productPrice = 'precio';
  static const productImage = 'imagen';
  static const productCategory = 'categoria';
  static const productColor = 'color';
  static const productWeight = 'peso';
  static const productBrand = 'marca';
  static const productQuantity = 'cantidad';
  static const productStatus = 'estado';
  static const productCreatedAt = 'fecha_creacion';
  static const productUpdatedAt = 'fecha_actualizacion';

  // ============ COLUMNAS - PEDIDOS ============
  static const orderId = 'id';
  static const orderUserId = 'usuario_id';
  static const orderClientId = 'cliente_id';
  static const orderDate = 'fecha_pedido';
  static const orderDueDate = 'fecha_entrega';
  static const orderTotal = 'total';
  static const orderStatus = 'estado';
  static const orderNotes = 'notas';
  static const orderContacto = 'contacto_cliente';

  // ============ COLUMNAS - ITEMS DE PEDIDOS ============
  static const orderItemId = 'id';
  static const orderItemOrderId = 'pedido_id';
  static const orderItemProductId = 'producto_id';
  static const orderItemProductName = 'nombre_producto';
  static const orderItemQuantity = 'cantidad';
  static const orderItemUnitPrice = 'precio_unitario';

  // ============ COLUMNAS - CLIENTES ============
  static const clientId = 'id';
  static const clientName = 'nombre';
  static const clientEmail = 'email';
  static const clientPhone = 'telefono';
  static const clientAddress = 'direccion';

  // ============ COLUMNAS - DESIGNS ============
  static const designId = 'id';
  static const designName = 'nombre';
  static const designDescription = 'descripcion';
  static const designUserId = 'usuario_id';
  static const designCreatedAt = 'fecha_creacion';
  static const designUpdatedAt = 'fecha_actualizacion';

  // ============ COLUMNAS - PATTERNS ============
  static const patternId = 'id';
  static const patternName = 'nombre';
  static const patternType = 'tipo';
  static const patternDesignId = 'design_id';
  static const patternDifficulty = 'dificultad';
  static const patternMaterial = 'material_sugerido';
  static const patternHookSize = 'tamano_gancho';
  static const patternStatus = 'estado';
  static const patternRawText = 'texto_patron';
  static const patternUserId = 'usuario_id';
  static const patternCreatedAt = 'fecha_creacion';
  static const patternUpdatedAt = 'fecha_actualizacion';

  // ============ COLUMNAS - CATALOG_SETTINGS ============
  static const catalogId = 'id';
  static const catalogUserId = 'usuario_id';
  static const catalogIsPublic = 'es_publico';
  static const catalogBusinessName = 'nombre_negocio';       // <-- NUEVO
  static const catalogContactEmail = 'email_contacto';       // <-- NUEVO
  static const catalogContactPhone = 'telefono_contacto';    // <-- NUEVO
  static const catalogContactInstagram = 'instagram_contacto';// <-- NUEVO
  static const catalogFeaturedProducts = 'productos_destacados';
  static const catalogFeaturedPatterns = 'patrones_destacados';// <-- NUEVO
  static const catalogCreatedAt = 'fecha_creacion';
  static const catalogUpdatedAt = 'fecha_actualizacion';

  // Singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa la base de datos
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Crea las tablas
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUsers (
        $userId INTEGER PRIMARY KEY AUTOINCREMENT,
        $userUid TEXT NOT NULL UNIQUE,
        $userEmail TEXT NOT NULL UNIQUE,
        $userDisplayName TEXT DEFAULT '',
        $userPhotoUrl TEXT DEFAULT '',
        $userAuthProvider TEXT DEFAULT 'email',
        $userSettings TEXT DEFAULT '{}', -- Nueva columna
        $userCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        $userUpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de Productos (con todos los campos del ProductModel)
    await db.execute('''
      CREATE TABLE $tableProducts (
        $productId INTEGER PRIMARY KEY AUTOINCREMENT,
        $productName TEXT NOT NULL UNIQUE,
        $productDescription TEXT DEFAULT '',
        $productPrice REAL NOT NULL,
        $productImage TEXT DEFAULT '',
        $productCategory TEXT DEFAULT '',
        $productColor TEXT DEFAULT '',
        $productWeight TEXT DEFAULT '',
        $productBrand TEXT DEFAULT '',
        $productQuantity INTEGER DEFAULT 0,
        $productStatus TEXT DEFAULT 'available',
        $productCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        $productUpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de Clientes
    await db.execute('''
      CREATE TABLE $tableClients (
        $clientId INTEGER PRIMARY KEY AUTOINCREMENT,
        $clientName TEXT NOT NULL,
        $clientEmail TEXT UNIQUE,
        $clientPhone TEXT,
        $clientAddress TEXT
      )
    ''');

    // Tabla de Pedidos
   await db.execute('''
      CREATE TABLE $tableOrders (
        $orderId INTEGER PRIMARY KEY AUTOINCREMENT,
        $orderUserId TEXT NOT NULL,
        $orderClientId INTEGER,
        $orderDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        $orderDueDate TIMESTAMP,
        $orderTotal REAL NOT NULL,
        $orderStatus TEXT DEFAULT 'pending',
        $orderNotes TEXT DEFAULT '',
        $orderContacto TEXT DEFAULT '',
        $orderItemsJson TEXT DEFAULT '[]',
        FOREIGN KEY ($orderClientId) REFERENCES $tableClients($clientId) ON DELETE CASCADE
      )
    ''');

    // Tabla de Items de Pedidos (relación muchos-a-muchos)
    await db.execute('''
      CREATE TABLE $tableOrderItems (
        $orderItemId INTEGER PRIMARY KEY AUTOINCREMENT,
        $orderItemOrderId INTEGER NOT NULL,
        $orderItemProductId INTEGER NOT NULL,
        $orderItemProductName TEXT NOT NULL,
        $orderItemQuantity INTEGER NOT NULL,
        $orderItemUnitPrice REAL NOT NULL,
        FOREIGN KEY ($orderItemOrderId) REFERENCES $tableOrders($orderId) ON DELETE CASCADE,
        FOREIGN KEY ($orderItemProductId) REFERENCES $tableProducts($productId)
      )
    ''');

    // Tabla de Designs
    await db.execute('''
      CREATE TABLE $tableDesigns (
        $designId INTEGER PRIMARY KEY AUTOINCREMENT,
        $designName TEXT NOT NULL,
        $designDescription TEXT DEFAULT '',
        $designUserId TEXT NOT NULL,
        $designCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        $designUpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // Manejo de actualizaciones de BD (para versiones futuras)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración de v1 a v2: Agregar campos faltantes a productos
      try {
        await db.execute('ALTER TABLE $tableProducts ADD COLUMN $productCategory TEXT DEFAULT ""');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableProducts ADD COLUMN $productColor TEXT DEFAULT ""');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableProducts ADD COLUMN $productWeight TEXT DEFAULT ""');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableProducts ADD COLUMN $productBrand TEXT DEFAULT ""');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableProducts ADD COLUMN $productQuantity INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableProducts ADD COLUMN $productStatus TEXT DEFAULT "available"');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableProducts ADD COLUMN $productUpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
      } catch (_) {}
      
      // Crear tabla de items de pedido si no existe
      try {
        await db.execute('''
          CREATE TABLE $tableOrderItems (
            $orderItemId INTEGER PRIMARY KEY AUTOINCREMENT,
            $orderItemOrderId INTEGER NOT NULL,
            $orderItemProductId INTEGER NOT NULL,
            $orderItemProductName TEXT NOT NULL,
            $orderItemQuantity INTEGER NOT NULL,
            $orderItemUnitPrice REAL NOT NULL,
            FOREIGN KEY ($orderItemOrderId) REFERENCES $tableOrders($orderId) ON DELETE CASCADE,
            FOREIGN KEY ($orderItemProductId) REFERENCES $tableProducts($productId)
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 3) {
      // Migración de v2 a v3: Crear tabla de usuarios
      try {
        await db.execute('''
          CREATE TABLE $tableUsers (
            $userId INTEGER PRIMARY KEY AUTOINCREMENT,
            $userUid TEXT NOT NULL UNIQUE,
            $userEmail TEXT NOT NULL UNIQUE,
            $userDisplayName TEXT DEFAULT '',
            $userPhotoUrl TEXT DEFAULT '',
            $userAuthProvider TEXT DEFAULT 'email',
            $userCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            $userUpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE $tableUsers ADD COLUMN $userSettings TEXT DEFAULT "{}"');
        await db.execute('ALTER TABLE $tableOrders ADD COLUMN $orderItemsJson TEXT DEFAULT "[]"');
      } catch (e) {
        print("Error en migración v4: $e");
      }
    }

    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE $tableOrders ADD COLUMN $orderUserId TEXT NOT NULL DEFAULT ""');
        await db.execute('ALTER TABLE $tableOrders ADD COLUMN $orderDueDate TIMESTAMP');
        await db.execute('ALTER TABLE $tableOrders ADD COLUMN $orderNotes TEXT DEFAULT ""');
        await db.execute('ALTER TABLE $tableOrders ADD COLUMN $orderContacto TEXT DEFAULT ""');
      } catch (e) {
        print("Error en migración v5: $e");
      }
    }

    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE $tableDesigns (
            $designId INTEGER PRIMARY KEY AUTOINCREMENT,
            $designName TEXT NOT NULL,
            $designDescription TEXT DEFAULT '',
            $designUserId TEXT NOT NULL,
            $designCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            $designUpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      } catch (e) {
        print("Error en migración v6: $e");
      }
    }

    if (oldVersion < 7) {
      try {
        await db.execute('''
          CREATE TABLE $tablePatterns (
            $patternId INTEGER PRIMARY KEY AUTOINCREMENT,
            $patternName TEXT NOT NULL,
            $patternType TEXT NOT NULL,
            $patternDesignId INTEGER NOT NULL,
            $patternDifficulty TEXT DEFAULT 'beginner',
            $patternMaterial TEXT DEFAULT '',
            $patternHookSize TEXT DEFAULT '',
            $patternStatus TEXT DEFAULT 'draft',
            $patternRawText TEXT DEFAULT '',
            $patternUserId TEXT NOT NULL,
            $patternCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            $patternUpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY ($patternDesignId) REFERENCES $tableDesigns($designId) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        print("Error en migración v7: $e");
      }
    }

    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE $tableCatalogSettings (
            $catalogId INTEGER PRIMARY KEY AUTOINCREMENT,
            $catalogUserId TEXT NOT NULL UNIQUE,
            $catalogIsPublic INTEGER DEFAULT 0,
            $catalogBusinessName TEXT DEFAULT '',
            $catalogContactEmail TEXT DEFAULT '',
            $catalogContactPhone TEXT DEFAULT '',
            $catalogContactInstagram TEXT DEFAULT '',
            $catalogFeaturedProducts TEXT DEFAULT '[]',
            $catalogFeaturedPatterns TEXT DEFAULT '[]',
            $catalogCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            $catalogUpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      } catch (e) {
        print("Error en migración v8: $e");
      }
    }
  }

  // ==========================================
  // MÉTODOS GENÉRICOS CRUD
  // ==========================================

  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<Map<String, dynamic>?> queryById(String table, int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> update(String table, Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) throw ArgumentError("El mapa debe contener la clave 'id' para actualizar '$table'");
    Database db = await instance.database;
    final data = Map<String, dynamic>.from(row)..remove('id');
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll(String table) async {
    Database db = await instance.database;
    await db.delete(table);
  }

  // ==========================================
  // MÉTODOS ESPECÍFICOS PARA CLIENTES
  // ==========================================

  Future<int> addClient(String nombre, String? email, String? telefono, String? direccion) async {
    return await insert(tableClients, {
      clientName: nombre,
      clientEmail: email,
      clientPhone: telefono,
      clientAddress: direccion,
    });
  }

  Future<List<Map<String, dynamic>>> getAllClients() async {
    return await queryAll(tableClients);
  }

  Future<int> updateClient(int id, {String? nombre, String? email, String? telefono, String? direccion}) async {
    Map<String, dynamic> updates = {'id': id};
    if (nombre != null) updates[clientName] = nombre;
    if (email != null) updates[clientEmail] = email;
    if (telefono != null) updates[clientPhone] = telefono;
    if (direccion != null) updates[clientAddress] = direccion;
    return await update(tableClients, updates);
  }

  Future<int> deleteClient(int id) async {
    return await delete(tableClients, id);
  }
// ==========================================
// MÉTODOS DE PEDIDOS E INVENTARIO transacciones pues
// ==========================================

/// Crea un pedido completo y actualiza el stock usando una transacción.
Future<int> createOrderFull(OrderModel order) async {
  final db = await database;

  return await db.transaction((txn) async {
    // 1. Insertar la cabecera del pedido
    final int orderId = await txn.insert(tableOrders, order.toMap());

    // 2. Procesar cada ítem
    for (var item in order.items) {
      // Guardar el ítem vinculado al pedido
      await txn.insert(tableOrderItems, {
        'pedido_id': orderId,
        'producto_id': item.productId,
        'nombre_producto': item.productName,
        'cantidad': item.quantity,
        'precio_unitario': item.unitPrice,
      });

      // 3. Descontar stock del producto
      if (item.productId != null) {
        await txn.rawUpdate('''
          UPDATE $tableProducts 
          SET $productQuantity = $productQuantity - ?, 
              $productUpdatedAt = ? 
          WHERE $productId = ?
        ''', [item.quantity, DateTime.now().toIso8601String(), item.productId]);
      }
    }
    return orderId;
  });
}
/// Obtiene un pedido por su ID (incluyendo el nombre del cliente)
  Future<OrderModel?> getOrderById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT o.*, c.$clientName as nombre_cliente
      FROM $tableOrders o
      LEFT JOIN $tableClients c ON o.$orderClientId = c.$clientId
      WHERE o.$orderId = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      // Buscamos los ítems de este pedido específico
      final List<Map<String, dynamic>> itemMaps = await db.query(
        tableOrderItems,
        where: 'pedido_id = ?',
        whereArgs: [id],
      );
      
      final items = itemMaps.map((i) => OrderItem.fromMap(i)).toList();
      return OrderModel.fromMap(maps.first, items: items);
    }
    return null;
  }

/// Actualiza únicamente el estado de un pedido (ej: de 'pending' a 'completed')
  Future<int> updateOrderStatus(int id, String status) async {
    final db = await database;
    return await db.update(
      tableOrders,
      {orderStatus: status}, // 'estado' en tu tabla
      where: '$orderId = ?', // 'id' en tu tabla
      whereArgs: [id],
    );
  }

  /// Actualiza un pedido completo con todos sus datos
  Future<void> updateOrder(OrderModel order) async {
    if (order.id == null) throw Exception('El pedido debe tener un ID para actualizar');
    
    final db = await database;
    await db.transaction((txn) async {
      // 1. Actualizar la cabecera del pedido
      await txn.update(
        tableOrders,
        {
          orderUserId: order.userId,
          orderClientId: order.clientId,
          orderDate: order.createdAt.toIso8601String(),
          orderDueDate: order.dueDate?.toIso8601String(),
          orderTotal: order.totalPrice,
          orderStatus: order.status.value,
          orderNotes: order.notes,
          orderContacto: order.customerContact,
        },
        where: '$orderId = ?',
        whereArgs: [order.id],
      );

      // 2. Actualizar los ítems si están presentes
      if (order.items.isNotEmpty) {
        // Primero eliminar los ítems antiguos
        await txn.delete(
          tableOrderItems,
          where: '$orderItemOrderId = ?',
          whereArgs: [order.id],
        );
        
        // Luego insertar los nuevos
        for (var item in order.items) {
          await txn.insert(tableOrderItems, {
            orderItemOrderId: order.id,
            orderItemProductId: item.productId,
            orderItemProductName: item.productName,
            orderItemQuantity: item.quantity,
            orderItemUnitPrice: item.unitPrice,
          });
        }
      }
    });
  }
/// Obtiene todos los pedidos con sus ítems incluidos
Future<List<OrderModel>> getAllOrdersWithItems() async {
  final db = await database;

  // Consulta con JOIN para datos del cliente
  final List<Map<String, dynamic>> orderMaps = await db.rawQuery('''
    SELECT o.*, c.$clientName as nombre_cliente 
    FROM $tableOrders o
    LEFT JOIN $tableClients c ON o.$orderClientId = c.$clientId
    ORDER BY o.$orderDate DESC
  ''');

  List<OrderModel> orders = [];

  for (var oMap in orderMaps) {
    // Para cada pedido, buscamos sus ítems
    final List<Map<String, dynamic>> itemMaps = await db.query(
      tableOrderItems,
      where: 'pedido_id = ?',
      whereArgs: [oMap['id']],
    );

    final items = itemMaps.map((i) => OrderItem.fromMap(i)).toList();
    orders.add(OrderModel.fromMap(oMap, items: items));
  }

  return orders;
}

/// Elimina un pedido y REVIERTE el stock (opcional, muy útil si se cancela)
Future<void> cancelAndReturnStock(int orderId) async {
  final db = await database;

  await db.transaction((txn) async {
    // 1. Obtener los ítems para saber cuánto devolver al stock
    final List<Map<String, dynamic>> items = await txn.query(
      tableOrderItems, 
      where: 'pedido_id = ?', 
      whereArgs: [orderId]
    );

    for (var item in items) {
      await txn.rawUpdate(
        'UPDATE $tableProducts SET $productQuantity = $productQuantity + ? WHERE $productId = ?',
        [item['cantidad'], item['producto_id']]
      );
    }

    // 2. Borrar ítems y pedido
    await txn.delete(tableOrderItems, where: 'pedido_id = ?', whereArgs: [orderId]);
    await txn.delete(tableOrders, where: 'id = ?', whereArgs: [orderId]);
  });
}
// ==========================================
  // MÉTODOS ESPECÍFICOS PARA PRODUCTOS (INVENTARIO)
  // ==========================================

  /// Inserta un nuevo producto
  Future<int> addProduct(Map<String, dynamic> productData) async {
    return await insert(tableProducts, productData);
  }

  /// Obtiene todos los productos ordenados por nombre
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    Database db = await instance.database;
    return await db.query(tableProducts, orderBy: '$productName ASC');
  }

  /// Actualiza un producto por su ID
  Future<int> updateProduct(int id, Map<String, dynamic> updates) async {
    Database db = await instance.database;
    return await db.update(
      tableProducts,
      updates,
      where: '$productId = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un producto
  Future<int> deleteProduct(int id) async {
    return await delete(tableProducts, id);
  }

  /// Obtiene la cantidad actual de stock de un producto
  Future<int?> getProductQuantity(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      tableProducts,
      columns: [productQuantity],
      where: '$productId = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first[productQuantity] as int : null;
  }

  /// Actualiza la cantidad de stock directamente
  Future<void> updateProductQuantity(int id, int newQuantity) async {
    Database db = await instance.database;
    await db.update(
      tableProducts,
      {
        productQuantity: newQuantity,
        productUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '$productId = ?',
      whereArgs: [id],
    );
  }

  /// Busca productos por coincidencia de texto
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    Database db = await instance.database;
    return await db.query(
      tableProducts,
      where: '$productName LIKE ? OR $productDescription LIKE ? OR categoria LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
  }

  /// Filtra productos por categoría
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    Database db = await instance.database;
    return await db.query(
      tableProducts,
      where: 'categoria = ?',
      whereArgs: [category],
    );
  }
  // ==========================================
  // MÉTODOS ESPECÍFICOS PARA USUARIOS
  // ==========================================

  // --- Ajustar el método addUser para que use el objeto directamente ---
  Future<int> addUser(dynamic userModel) async {
    Database db = await instance.database;
    // Ahora enviamos el map completo que genera el modelo
    return await db.insert(
      tableUsers, 
      userModel.toMap(), 
      conflictAlgorithm: ConflictAlgorithm.replace // Si el usuario existe, lo actualiza
    );
  }


  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> results = await db.query(
      tableUsers,
      where: '$userUid = ?',
      whereArgs: [uid],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(dynamic userModel) async {
    Database db = await instance.database;
    final map = userModel.toMap();
    return await db.update(
      tableUsers,
      map,
      where: '$userUid = ?',
      whereArgs: [map[userUid]],
    );
  }

  Future<int> deleteUser(String uid) async {
    Database db = await instance.database;
    return await db.delete(
      tableUsers,
      where: '$userUid = ?',
      whereArgs: [uid],
    );
  }

  // ==========================================
  // MÉTODO PARA CERRAR LA BD
  // ==========================================

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
// ==========================================
  // MÉTODOS ESPECÍFICOS PARA DESIGNS
  // ==========================================

  Future<void> createDesign(DesignModel designModel) async {
    final db = await database;
    await db.insert(tableDesigns, designModel.toMap());
  }

  Future<List<DesignModel>> getAllDesigns() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableDesigns,
      orderBy: '$designCreatedAt DESC',
    );
    return maps.map((m) => DesignModel.fromMap(m)).toList();
  }

  Future<DesignModel?> getDesignById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableDesigns,
      where: '$designId = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? DesignModel.fromMap(maps.first) : null;
  }

  Future<void> updateDesign(DesignModel designModel) async {
    final db = await database;
    await db.update(
      tableDesigns,
      designModel.toMap(),
      where: '$designId = ?',
      whereArgs: [designModel.id], // <-- Usamos directamente el ID del modelo
    );
  }

  Future<void> deleteDesign(int id) async {
    final db = await database;
    await db.delete(
      tableDesigns,
      where: '$designId = ?',
      whereArgs: [id],
    );
  }
  // ==========================================
  // MÉTODOS ESPECÍFICOS PARA PATTERNS
  // ==========================================

  Future<void> createPattern(dynamic patternModel) async {
    final db = await database;
    await db.insert(tablePatterns, patternModel.toMap());
  }

  Future<List<PatternModel>> getAllPatterns() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePatterns,
      orderBy: '$patternCreatedAt DESC',
    );
    return maps.map((m) => PatternModel.fromMap(m)).toList();
  }

  Future<List<PatternModel>> getPatternsByUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePatterns,
      where: '$patternUserId = ?',
      whereArgs: [userId],
      orderBy: '$patternCreatedAt DESC',
    );
    return maps.map((m) => PatternModel.fromMap(m)).toList();
  }

  Future<List<PatternModel>> getPatternsByDesign(int designId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePatterns,
      where: '$patternDesignId = ?',
      whereArgs: [designId],
      orderBy: '$patternCreatedAt DESC',
    );
    return maps.map((m) => PatternModel.fromMap(m)).toList();
  }

  Future<PatternModel?> getPatternById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablePatterns,
      where: '$patternId = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? PatternModel.fromMap(maps.first) : null;
  }

  Future<void> updatePattern(dynamic patternModel) async {
    final db = await database;
    final map = patternModel.toMap();
    await db.update(
      tablePatterns,
      map,
      where: '$patternId = ?',
      whereArgs: [map['id']],
    );
  }

  Future<void> deletePattern(int id) async {
    final db = await database;
    await db.delete(
      tablePatterns,
      where: '$patternId = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePatternsByDesign(int designId) async {
    final db = await database;
    await db.delete(
      tablePatterns,
      where: '$patternDesignId = ?',
      whereArgs: [designId],
    );
  }

  // ==========================================
  // MÉTODOS ESPECÍFICOS PARA CATALOG_SETTINGS
  // ==========================================

  Future<void> updateCatalogSettings(String userId, Map<String, dynamic> data) async {
    final db = await database;
    final existing = await db.query(
      tableCatalogSettings,
      where: '$catalogUserId = ?',
      whereArgs: [userId],
    );

    if (existing.isEmpty) {
      await db.insert(tableCatalogSettings, {
        ...data,
        catalogUserId: userId,
        catalogCreatedAt: DateTime.now().toIso8601String(),
        catalogUpdatedAt: DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        tableCatalogSettings,
        {
          ...data,
          catalogUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '$catalogUserId = ?',
        whereArgs: [userId],
      );
    }
  }

  Future<Map<String, dynamic>?> getCatalogSettings(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCatalogSettings,
      where: '$catalogUserId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }
  // ─────────────────────────────────────────────────────────────────────────
  //  Catálogo Público (Landing)
  // ─────────────────────────────────────────────────────────────────────────

  
}