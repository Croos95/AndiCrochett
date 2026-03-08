import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';

/// Repositorio de agenda/pedidos  CRUD sobre la colección orders en Firestore.
class AgendaRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _collection => _db.collection('orders');

  /// Obtener todos los pedidos del usuario.
  Future<List<OrderModel>> getOrders(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate', descending: false)
        .get();
    return snapshot.docs.map((d) => OrderModel.fromDocument(d)).toList();
  }

  /// Stream en tiempo real de pedidos del usuario.
  Stream<List<OrderModel>> watchOrders(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromDocument(d)).toList());
  }

  /// Obtener pedidos por estado.
  Future<List<OrderModel>> getOrdersByStatus(
      String userId, String status) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('dueDate', descending: false)
        .get();
    return snapshot.docs.map((d) => OrderModel.fromDocument(d)).toList();
  }

  /// Obtener un pedido por ID.
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _collection.doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromDocument(doc);
  }

  /// Crear un pedido nuevo.
  Future<String> createOrder(OrderModel order) async {
    final doc = await _collection.add(order.toMap());
    return doc.id;
  }

  /// Actualizar un pedido existente.
  Future<void> updateOrder(OrderModel order) async {
    await _collection.doc(order.id).update(order.toMap());
  }

  /// Actualizar solo el estado de un pedido.
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _collection.doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Eliminar un pedido.
  Future<void> deleteOrder(String orderId) async {
    await _collection.doc(orderId).delete();
  }

  /// Contar pedidos pendientes del usuario.
  Future<int> countPendingOrders(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
