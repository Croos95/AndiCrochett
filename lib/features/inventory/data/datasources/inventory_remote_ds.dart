import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';

/// Datasource remoto para inventario  acceso directo a Firestore.
///
/// Usado por [InventoryRepository] como fuente de datos.
class InventoryRemoteDataSource {
  final FirebaseFirestore _db;
  static const _collectionPath = 'products';

  InventoryRemoteDataSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _db.collection(_collectionPath);

  /// Obtener todos los productos de un usuario.
  Future<List<ProductModel>> fetchProducts(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => ProductModel.fromDocument(d)).toList();
  }

  /// Stream de productos del usuario.
  Stream<List<ProductModel>> streamProducts(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ProductModel.fromDocument(d)).toList());
  }

  /// Obtener un producto por ID.
  Future<ProductModel?> fetchProduct(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromDocument(doc);
  }

  /// Crear producto, retorna ID generado.
  Future<String> create(Map<String, dynamic> data) async {
    final doc = await _collection.add(data);
    return doc.id;
  }

  /// Actualizar producto.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  /// Eliminar producto.
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
