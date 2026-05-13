import 'package:andicrochett/core/services/analytics_service.dart';
import 'package:andicrochett/core/services/api_client.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';

/// Repositorio de Inventario contra la API REST.
/// El stock y el estado del producto se calculan en el servidor.
class InventoryRepository {
  InventoryRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  static const _basePath = '/products';

  // ── Lectura ───────────────────────────────────────────────────────────────

  Future<List<ProductModel>> getAllProducts() async {
    final data = await _api.get(_basePath) as List<dynamic>;
    return data.map((m) => ProductModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<ProductModel?> getProductById(int id) async {
    try {
      final data = await _api.get('$_basePath/$id') as Map<String, dynamic>;
      return ProductModel.fromMap(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final data = await _api.get(_basePath, query: {'q': query}) as List<dynamic>;
    return data.map((m) => ProductModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final data = await _api.get(_basePath, query: {'categoria': category}) as List<dynamic>;
    return data.map((m) => ProductModel.fromMap(m as Map<String, dynamic>)).toList();
  }

  // ── Stock ────────────────────────────────────────────────────────────────

  /// Actualiza el stock a un valor absoluto. El backend recalcula el estado.
  Future<void> updateProductStock(int id, int newQuantity) async {
    await _api.patch('$_basePath/$id/stock', body: {'cantidad': newQuantity});
  }

  /// Incrementa o decrementa el stock. El backend recalcula el estado.
  Future<void> adjustStock(int productId, int delta) async {
    await _api.post('$_basePath/$productId/adjust-stock', body: {'delta': delta});
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  Future<int> createProduct(ProductModel product) async {
    final body = _toBody(product);
    final data = await _api.post(_basePath, body: body) as Map<String, dynamic>;
    final created = ProductModel.fromMap(data);

    if (created.id != null) {
      AnalyticsService.instance.logProductCreated(
        productId: created.id!,
        name: created.name,
      );
    }
    return created.id ?? 0;
  }

  Future<int> updateProduct(ProductModel product) async {
    if (product.id == null) throw Exception('El producto debe tener un ID');
    final body = _toBody(product);
    await _api.put('$_basePath/${product.id}', body: body);
    return 1; // por compatibilidad con la firma anterior (número de filas afectadas)
  }

  Future<int> deleteProduct(int id) async {
    await _api.delete('$_basePath/$id');
    return 1;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toBody(ProductModel p) => {
    'nombre': p.name,
    'descripcion': p.description,
    'precio': p.price,
    'imagen': p.imageUrl,
    'categoria': p.category,
    'color': p.color,
    'peso': p.weight,
    'marca': p.brand,
    'cantidad': p.currentStock,
    'estado': p.status.sqliteValue,
  };
}
