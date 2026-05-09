import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Configuración de la base de datos
  static const _databaseName = "andicrochett.db";
  static const _databaseVersion = 2;

  // ============ TABLAS ============
  static const tableProducts = 'productos';
  static const tableOrders = 'pedidos';
  static const tableOrderItems = 'items_pedido';
  static const tableClients = 'clientes';

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
  static const orderClientId = 'cliente_id';
  static const orderDate = 'fecha_pedido';
  static const orderTotal = 'total';
  static const orderStatus = 'estado';

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
        $orderClientId INTEGER NOT NULL,
        $orderDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        $orderTotal REAL NOT NULL,
        $orderStatus TEXT DEFAULT 'pending',
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
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
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
  // MÉTODOS ESPECÍFICOS PARA PRODUCTOS
  // ==========================================

  Future<int> addProduct(Map<String, dynamic> productData) async {
    return await insert(tableProducts, productData);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    return await queryAll(tableProducts);
  }

  Future<Map<String, dynamic>?> getProductById(int id) async {
    return await queryById(tableProducts, id);
  }

  Future<int> updateProduct(int id, Map<String, dynamic> updates) async {
    updates['id'] = id;
    updates[productUpdatedAt] = DateTime.now().toIso8601String();
    return await update(tableProducts, updates);
  }

  Future<int> deleteProduct(int id) async {
    return await delete(tableProducts, id);
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    Database db = await instance.database;
    return await db.query(
      tableProducts,
      where: '$productName LIKE ? OR $productDescription LIKE ? OR $productCategory LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
  }

  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    Database db = await instance.database;
    return await db.query(
      tableProducts,
      where: '$productCategory = ?',
      whereArgs: [category],
    );
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
  // MÉTODOS ESPECÍFICOS PARA PEDIDOS
  // ==========================================

  Future<int> addOrder(int clientId, double total, {String status = 'pending'}) async {
    return await insert(tableOrders, {
      orderClientId: clientId,
      orderTotal: total,
      orderStatus: status,
    });
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    Database db = await instance.database;
    return await db.rawQuery('''
      SELECT o.*, c.$clientName as cliente_nombre, c.$clientEmail as cliente_email
      FROM $tableOrders o
      LEFT JOIN $tableClients c ON o.$orderClientId = c.$clientId
      ORDER BY o.$orderDate DESC
    ''');
  }

  Future<Map<String, dynamic>?> getOrderById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT o.*, c.$clientName as cliente_nombre, c.$clientEmail as cliente_email
      FROM $tableOrders o
      LEFT JOIN $tableClients c ON o.$orderClientId = c.$clientId
      WHERE o.$orderId = ?
    ''', [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getOrdersByClient(int clientId) async {
    Database db = await instance.database;
    return await db.query(
      tableOrders,
      where: '$orderClientId = ?',
      whereArgs: [clientId],
      orderBy: '$orderDate DESC',
    );
  }

  Future<int> updateOrderStatus(int orderId, String status) async {
    return await update(tableOrders, {
      'id': orderId,
      orderStatus: status,
    });
  }

  Future<int> deleteOrder(int id) async {
    // Primero elimina los items (la cascada debería hacerlo, pero nos aseguramos)
    Database db = await instance.database;
    await db.delete(tableOrderItems, where: '$orderItemOrderId = ?', whereArgs: [id]);
    return await delete(tableOrders, id);
  }

  // ==========================================
  // MÉTODOS ESPECÍFICOS PARA ITEMS DE PEDIDOS
  // ==========================================

  Future<int> addOrderItem(int orderId, int productId, String productName, int quantity, double unitPrice) async {
    return await insert(tableOrderItems, {
      orderItemOrderId: orderId,
      orderItemProductId: productId,
      orderItemProductName: productName,
      orderItemQuantity: quantity,
      orderItemUnitPrice: unitPrice,
    });
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    Database db = await instance.database;
    return await db.query(
      tableOrderItems,
      where: '$orderItemOrderId = ?',
      whereArgs: [orderId],
    );
  }

  Future<int> deleteOrderItem(int itemId) async {
    return await delete(tableOrderItems, itemId);
  }

  Future<void> deleteAllOrderItems(int orderId) async {
    Database db = await instance.database;
    await db.delete(tableOrderItems, where: '$orderItemOrderId = ?', whereArgs: [orderId]);
  }

  // ==========================================
  // MÉTODOS PARA GESTIÓN DE STOCK
  // ==========================================

  Future<int?> getProductQuantity(int productId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      tableProducts,
      columns: [productQuantity],
      where: '$productId = ?',
      whereArgs: [productId],
    );
    return result.isNotEmpty ? result.first[productQuantity] as int : null;
  }

  Future<void> updateProductQuantity(int productId, int newQuantity) async {
    Database db = await instance.database;
    await db.update(
      tableProducts,
      {
        productQuantity: newQuantity,
        productUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '$productId = ?',
      whereArgs: [productId],
    );
  }

  Future<void> decrementProductQuantity(int productId, int amount) async {
    Database db = await instance.database;
    await db.rawUpdate(
      'UPDATE $tableProducts SET $productQuantity = $productQuantity - ?, $productUpdatedAt = ? WHERE $productId = ?',
      [amount, DateTime.now().toIso8601String(), productId],
    );
  }

  Future<void> incrementProductQuantity(int productId, int amount) async {
    Database db = await instance.database;
    await db.rawUpdate(
      'UPDATE $tableProducts SET $productQuantity = $productQuantity + ?, $productUpdatedAt = ? WHERE $productId = ?',
      [amount, DateTime.now().toIso8601String(), productId],
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
}