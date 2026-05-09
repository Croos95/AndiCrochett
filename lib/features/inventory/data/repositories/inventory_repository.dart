import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';

/// Repositorio de Inventario usando SQLite como BD principal.
class InventoryRepository {
  InventoryRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Obtiene todos los productos.
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final results = await _db.getAllProducts();
      return results.map((map) => ProductModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  /// Obtiene un producto por ID.
  Future<ProductModel?> getProductById(int id) async {
    try {
      final result = await _db.queryById(DatabaseHelper.tableProducts, id);
      return result != null ? ProductModel.fromMap(result) : null;
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  /// Obtiene productos con bajo stock.
  Future<List<ProductModel>> getLowStockProducts({int threshold = 5}) async {
    try {
      final all = await getAllProducts();
      return all.where((p) => p.currentStock < threshold && p.currentStock > 0).toList();
    } catch (e) {
      throw Exception('Error al obtener productos con bajo stock: $e');
    }
  }

  /// Obtiene productos sin stock.
  Future<List<ProductModel>> getOutOfStockProducts() async {
    try {
      final all = await getAllProducts();
      return all.where((p) => p.currentStock == 0).toList();
    } catch (e) {
      throw Exception('Error al obtener productos sin stock: $e');
    }
  }

  /// Crea un nuevo producto.
  Future<int> createProduct(ProductModel product) async {
    try {
      final productData = product.toMap();
      final id = await _db.addProduct(productData);
      return id;
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  /// Actualiza un producto existente.
  Future<int> updateProduct(ProductModel product) async {
    try {
      if (product.id == null) throw Exception('El producto debe tener un ID');
      final updates = product.toMap();
      return await _db.updateProduct(product.id!, updates);
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  /// Elimina un producto por ID.
  Future<int> deleteProduct(int id) async {
    try {
      return await _db.deleteProduct(id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  /// Actualiza el stock de un producto.
  Future<void> updateProductStock(int id, int newQuantity) async {
    try {
      return await _db.updateProductQuantity(id, newQuantity);
    } catch (e) {
      throw Exception('Error al actualizar stock: $e');
    }
  }

  /// Incrementa o decrementa el stock.
  Future<void> adjustStock(int productId, int delta) async {
    try {
      final currentQuantity = await _db.getProductQuantity(productId);
      final newQuantity = (currentQuantity ?? 0) + delta;
      if (newQuantity < 0) throw Exception('El stock no puede ser negativo');
      return await updateProductStock(productId, newQuantity);
    } catch (e) {
      throw Exception('Error al ajustar stock: $e');
    }
  }

  /// Busca productos por nombre, descripción o categoría.
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final results = await _db.searchProducts(query);
      return results.map((map) => ProductModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al buscar productos: $e');
    }
  }

  /// Obtiene productos por categoría.
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final results = await _db.getProductsByCategory(category);
      return results.map((map) => ProductModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos por categoría: $e');
    }
  }

  /// Observable para cambios en el inventario (para sincronización local).
  /// Este método debería integrar con un BLoC o Provider si se requiere reactividad.
  Stream<List<ProductModel>> watchByUser(String userId) async* {
    // Por ahora solo retorna los productos, pero puede extenderse para sincronización
    try {
      yield await getAllProducts();
    } catch (e) {
      throw Exception('Error al observar productos: $e');
    }
  }
}
