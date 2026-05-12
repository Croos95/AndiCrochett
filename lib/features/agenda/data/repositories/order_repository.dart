import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';

/// Repositorio de Pedidos: Actúa como mediador entre la UI y la Base de Datos.
class OrderRepository {
  OrderRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  // ── Streams (polling) ─────────────────────────────────────────────────────

  Stream<List<OrderModel>> watchByUser(String userId) async* {
    yield await _fetchOrdersByUser(userId);
    yield* _streamWithRefresh(() => _fetchOrdersByUser(userId));
  }

  Stream<T> _streamWithRefresh<T>(Future<T> Function() fetch) async* {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield await fetch();
    }
  }

  Future<List<OrderModel>> _fetchOrdersByUser(String userId) async {
    try {
      final all = await _db.getAllOrdersWithItems();
      return all.where((o) => o.userId == userId).toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos del usuario: $e');
    }
  }

  // ── Lectura ───────────────────────────────────────────────────────────────

  Future<List<OrderModel>> getAllOrders() async {
    try {
      return await _db.getAllOrdersWithItems();
    } catch (e) {
      throw Exception('Error al obtener la lista de pedidos: $e');
    }
  }

  Future<OrderModel?> getOrderById(int id) async {
    try {
      return await _db.getOrderById(id);
    } catch (e) {
      throw Exception('Error al obtener el pedido #$id: $e');
    }
  }

  Future<List<OrderModel>> getOrdersByClient(int clientId) async {
    try {
      final all = await _db.getAllOrdersWithItems();
      return all.where((o) => o.clientId == clientId).toList();
    } catch (e) {
      throw Exception('Error al filtrar pedidos por cliente: $e');
    }
  }

  Future<List<OrderModel>> getActiveOrders() async {
    try {
      final all = await _db.getAllOrdersWithItems();
      return all
          .where(
            (o) =>
                o.status == OrderStatus.pending ||
                o.status == OrderStatus.inProgress,
          )
          .toList();
    } catch (e) {
      throw Exception('Error al cargar la agenda: $e');
    }
  }

  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status) async {
    try {
      final all = await _db.getAllOrdersWithItems();
      return all.where((o) => o.status == status).toList();
    } catch (e) {
      throw Exception('Error al filtrar pedidos: $e');
    }
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  Future<void> create(OrderModel order) async {
    try {
      if (order.userId.isEmpty) {
        throw Exception('El pedido debe tener un usuario válido.');
      }
      await _db.createOrderFull(order);
    } catch (e) {
      throw Exception('Error al crear el pedido: $e');
    }
  }

  Future<void> update(OrderModel order) async {
    try {
      if (order.id == null) {
        throw Exception('No se puede actualizar un pedido sin ID.');
      }
      await _db.updateOrder(order);
    } catch (e) {
      throw Exception('Error al actualizar el pedido: $e');
    }
  }

  Future<void> updateStatus(int orderId, OrderStatus status) async {
    try {
      await _db.updateOrderStatus(orderId, status.value);
    } catch (e) {
      throw Exception('Error al cambiar el estado del pedido: $e');
    }
  }

  Future<void> completeOrder(int id) async {
    await updateStatus(id, OrderStatus.completed);
  }

  Future<void> delete(int id) async {
    try {
      await _db.cancelAndReturnStock(id);
    } catch (e) {
      throw Exception('Error al cancelar el pedido: $e');
    }
  }

  void dispose() {}
}
