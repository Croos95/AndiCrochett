import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';

/// Acceso a Firestore para la colección 'products'.
class InventoryRepository {
  InventoryRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('products');

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Stream de todos los productos del usuario, ordenados por nombre.
  Stream<List<ProductModel>> watchByUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ProductModel.fromDoc).toList());

  /// Stream de productos con stock bajo.
  Stream<List<ProductModel>> watchLowStock(String userId) => _col
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: 'low_stock')
      .snapshots()
      .map((s) => s.docs.map(ProductModel.fromDoc).toList());

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Crea un producto y devuelve su ID.
  Future<String> create(ProductModel product) async {
    final now = DateTime.now();
    final ref = await _col.add(
      product.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
    return ref.id;
  }

  /// Actualiza un producto existente.
  Future<void> update(ProductModel product) async {
    await _col
        .doc(product.id)
        .update(product.copyWith(updatedAt: DateTime.now()).toMap());
  }

  /// Elimina un producto por ID.
  Future<void> delete(String id) => _col.doc(id).delete();

  /// Incrementa o decrementa el stock de un producto de forma atómica.
  Future<void> updateStock(String id, int delta) async {
    await _col.doc(id).update({
      'currentStock': FieldValue.increment(delta),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
