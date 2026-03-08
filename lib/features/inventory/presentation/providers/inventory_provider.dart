import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:andicrochett/features/inventory/data/repositories/inventory_repository.dart';

/// Provider / controlador de inventario.
///
/// Conecta la UI con Firestore a través de [InventoryRepository].
/// Usa [ChangeNotifier] para notificar a los widgets que escuchan.
class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repo = InventoryRepository();

  List<ProductModel> _products = [];
  bool _loading = false;
  String? _error;
  StreamSubscription? _subscription;

  //  Getters 

  List<ProductModel> get products => _products;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasProducts => _products.isNotEmpty;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  //  Lifecycle 

  /// Iniciar escucha en tiempo real de los productos del usuario.
  void startListening() {
    final uid = _uid;
    if (uid == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repo.watchProducts(uid).listen(
      (products) {
        _products = products;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  /// Detener la escucha.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Cargar productos una sola vez (sin stream).
  Future<void> loadProducts() async {
    final uid = _uid;
    if (uid == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _repo.getProducts(uid);
      _loading = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }

  //  CRUD 

  /// Crear un producto nuevo en Firestore.
  Future<String?> createProduct(ProductModel product) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final id = await _repo.createProduct(product.copyWith(userId: uid));
      // Si no estamos en modo stream, recargamos manualmente
      if (_subscription == null) await loadProducts();
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Actualizar un producto existente en Firestore.
  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _repo.updateProduct(product);
      if (_subscription == null) await loadProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Eliminar un producto de Firestore.
  Future<bool> deleteProduct(String productId) async {
    try {
      await _repo.deleteProduct(productId);
      if (_subscription == null) await loadProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Actualizar solo el stock de un producto.
  Future<bool> updateStock(String productId, int newStock) async {
    try {
      await _repo.updateStock(productId, newStock);
      if (_subscription == null) await loadProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  //  Cleanup 

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
