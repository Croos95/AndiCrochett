import 'package:andicrochett/core/services/analytics_service.dart';
import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';

class InventoryRepository {
  InventoryRepository({DatabaseHelper? dbHelper})
    : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Obtiene todos los productos del inventario.
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final results = await _db.getAllProducts();
      return results.map((map) => ProductModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  /// Obtiene un producto específico por ID.
  Future<ProductModel?> getProductById(int id) async {
    try {
      final result = await _db.queryById(DatabaseHelper.tableProducts, id);
      return result != null ? ProductModel.fromMap(result) : null;
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
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

  // ── Gestión de Stock y Estados ───────────────────────────────────────────

  /// Actualiza el stock y calcula automáticamente el nuevo estado.
  /// Este es el método central para cambios de cantidad.
  Future<void> updateProductStock(int id, int newQuantity) async {
    try {
      // 1. Lógica de negocio para determinar el estado
      String newState = 'available';
      if (newQuantity <= 0) {
        newState = 'out_of_stock';
      } else if (newQuantity <= 5) {
        // Puedes parametrizar este 5 si quieres
        newState = 'low_stock';
      }

      // 2. Aplicar actualización en la base de datos
      await _db.updateProduct(id, {
        'cantidad': newQuantity,
        'estado': newState,
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al actualizar stock y estado: $e');
    }
  }

  /// Incrementa o decrementa el stock actual.
  Future<void> adjustStock(int productId, int delta) async {
    try {
      final currentQuantity = await _db.getProductQuantity(productId);
      final newQuantity = (currentQuantity ?? 0) + delta;

      if (newQuantity < 0) {
        throw Exception('El stock no puede ser negativo');
      }

      // Reutilizamos la lógica centralizada de actualización
      await updateProductStock(productId, newQuantity);
    } catch (e) {
      throw Exception('Error al ajustar stock: $e');
    }
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Crea un nuevo producto en el inventario.
  Future<int> createProduct(ProductModel product) async {
    try {
      final id = await _db.addProduct(product.toMap());
      AnalyticsService.instance.logProductCreated(
        productId: id,
        name: product.name,
      );
      return id;
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  /// Actualiza los datos generales de un producto.
  Future<int> updateProduct(ProductModel product) async {
    try {
      if (product.id == null) throw Exception('El producto debe tener un ID');
      return await _db.updateProduct(product.id!, product.toMap());
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  /// Elimina un producto.
  Future<int> deleteProduct(int id) async {
    try {
      return await _db.deleteProduct(id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }
}
