import 'package:flutter/foundation.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:andicrochett/features/inventory/data/repositories/inventory_repository.dart';

enum InventoryStatus { initial, loading, loaded, error }

/// ChangeNotifier para la gestión del estado del inventario con SQLite.
class InventoryProvider extends ChangeNotifier {
  InventoryProvider({InventoryRepository? repository})
    : _repo = repository ?? InventoryRepository() {
    _init();
  }

  final InventoryRepository _repo;

  InventoryStatus _status = InventoryStatus.initial;
  InventoryStatus get status => _status;

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  List<ProductModel> _lowStockProducts = [];
  List<ProductModel> get lowStockProducts => _lowStockProducts;

  List<ProductModel> _outOfStockProducts = [];
  List<ProductModel> get outOfStockProducts => _outOfStockProducts;

  String? _error;
  String? get error => _error;

  bool _loadingInProgress = false;

  // ── Getters de conveniencia ────────────────────────────────────────────

  int get totalProducts => _products.length;
  int get totalStock =>
      _products.fold<int>(0, (sum, p) => sum + p.currentStock);

  // ── Inicialización ────────────────────────────────────────────────────────

  void _init() {
    loadProducts();
  }

  // ── Operaciones ───────────────────────────────────────────────────────────

  /// Carga todos los productos y organiza los estados en memoria
  Future<void> loadProducts() async {
    if (_loadingInProgress) return;
    _loadingInProgress = true;
    _status = InventoryStatus.loading;
    notifyListeners();

    try {
      // 1. Una sola consulta al repositorio para traer todo
      final allProducts = await _repo.getAllProducts();
      _products = allProducts;

      // 2. Filtramos la lista principal en memoria usando Dart
      // Esto es mucho más rápido que ir a la base de datos 3 veces
      _lowStockProducts = allProducts
          .where((p) => p.status == ProductStatus.lowStock)
          .toList();

      _outOfStockProducts = allProducts
          .where((p) => p.status == ProductStatus.outOfStock)
          .toList();

      _status = InventoryStatus.loaded;
      _error = null;
    } catch (e) {
      _status = InventoryStatus.error;
      _error = 'Error al cargar inventario: ${e.toString()}';
    } finally {
      _loadingInProgress = false;
    }

    notifyListeners();
  }

  /// Agrega un nuevo producto.
  Future<bool> addProduct(ProductModel product) async {
    try {
      await _repo.createProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _status = InventoryStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Actualiza un producto existente.
  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _repo.updateProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _status = InventoryStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Elimina un producto.
  Future<bool> deleteProduct(int id) async {
    try {
      await _repo.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      _status = InventoryStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Ajusta el stock de un producto.
  Future<bool> adjustStock(int productId, int delta) async {
    try {
      await _repo.adjustStock(productId, delta);
      await loadProducts();
      return true;
    } catch (e) {
      _status = InventoryStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Obtiene un producto por ID.
  Future<ProductModel?> getProductById(int id) async {
    try {
      return await _repo.getProductById(id);
    } catch (e) {
      _status = InventoryStatus.error;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
