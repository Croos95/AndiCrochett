import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';

/// Acceso a Firestore para la colección 'orders'.
class AgendaRepository {
  AgendaRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('orders');

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Stream de pedidos del usuario ordenados por fecha de entrega.
  Stream<List<OrderModel>> watchByUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('dueDate', descending: false)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  /// Stream filtrado por estado.
  Stream<List<OrderModel>> watchByStatus(String userId, OrderStatus status) =>
      _col
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status.firestoreValue)
          .orderBy('dueDate', descending: false)
          .snapshots()
          .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Crea un pedido y devuelve su ID.
  Future<String> create(OrderModel order) async {
    final now = DateTime.now();
    final ref = await _col.add(
      order.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
    return ref.id;
  }

  /// Actualiza un pedido existente.
  Future<void> update(OrderModel order) async {
    await _col
        .doc(order.id)
        .update(order.copyWith(updatedAt: DateTime.now()).toMap());
  }

  /// Elimina un pedido por ID.
  Future<void> delete(String id) => _col.doc(id).delete();

  /// Cambia el status de un pedido a completado.
  Future<void> completeOrder(String id) async {
    await _col.doc(id).update({
      'status': 'completed',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Cambia el status de un pedido.
  Future<void> updateStatus(String id, OrderStatus status) async {
    await _col.doc(id).update({
      'status': status.firestoreValue,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
