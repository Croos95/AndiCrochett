import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';

/// Repositorio de inventario  CRUD sobre la colección products en Firestore.
class InventoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _collection => _db.collection('products');

  /// Obtener todos los productos del usuario.
  Future<List<ProductModel>> getProducts(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => ProductModel.fromDocument(d)).toList();
  }

  /// Stream en tiempo real de productos del usuario.
  Stream<List<ProductModel>> watchProducts(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ProductModel.fromDocument(d)).toList());
  }

  /// Obtener un producto por ID.
  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _collection.doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromDocument(doc);
  }

  /// Crear un producto nuevo.
  Future<String> createProduct(ProductModel product) async {
    final doc = await _collection.add(product.toMap());
    return doc.id;
  }

  /// Actualizar un producto existente.
  Future<void> updateProduct(ProductModel product) async {
    await _collection.doc(product.id).update(product.toMap());
  }

  /// Eliminar un producto.
  Future<void> deleteProduct(String productId) async {
    await _collection.doc(productId).delete();
  }

  /// Actualizar solo el stock de un producto.
  Future<void> updateStock(String productId, int newStock) async {
    await _collection.doc(productId).update({
      'currentStock': newStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Obtener productos públicos (para catálogo).
  Future<List<ProductModel>> getPublicProducts() async {
    final snapshot = await _collection
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => ProductModel.fromDocument(d)).toList();
  }
}
