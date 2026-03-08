import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:andicrochett/features/inventory/data/repositories/inventory_repository.dart';

enum InventoryStatus { initial, loading, loaded, error }

/// ChangeNotifier para la gestión del estado del inventario.
class InventoryProvider extends ChangeNotifier {
  InventoryProvider({
    required String userId,
    InventoryRepository? repository,
  })  : _userId = userId,
        _repo = repository ?? InventoryRepository() {
    _init();
  }

  final String _userId;
  final InventoryRepository _repo;
  StreamSubscription<List<ProductModel>>? _sub;

  InventoryStatus _status = InventoryStatus.initial;
  InventoryStatus get status => _status;

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  String? _error;
  String? get error => _error;

  // ── Getters de conveniencia ────────────────────────────────────────────

  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.status == ProductStatus.lowStock).toList();

  List<ProductModel> get outOfStockProducts =>
      _products.where((p) => p.status == ProductStatus.outOfStock).toList();

  int get totalStock =>
      _products.fold<int>(0, (sum, p) => sum + p.currentStock);

  // ── Inicialización ────────────────────────────────────────────────────────

  void _init() {
    _status = InventoryStatus.loading;
    notifyListeners();

    _sub = _repo.watchByUser(_userId).listen(
      (data) {
        _products = data;
        _status = InventoryStatus.loaded;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _status = InventoryStatus.error;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // ── Operaciones CRUD ──────────────────────────────────────────────────────

  Future<String> addProduct(ProductModel product) async {
    return _repo.create(product.copyWith(userId: _userId));
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repo.update(product);
  }

  Future<void> deleteProduct(String id) async {
    await _repo.delete(id);
  }

  Future<void> updateStock(String id, int delta) async {
    await _repo.updateStock(id, delta);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
