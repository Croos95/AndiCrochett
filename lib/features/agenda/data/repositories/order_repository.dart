import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';

/// Repositorio de Pedidos usando SQLite
class OrderRepository {
  OrderRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Obtiene todos los pedidos.
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final results = await _db.getAllOrders();
      return results.map((map) => OrderModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos: $e');
    }
  }

  /// Obtiene un pedido por ID.
  Future<OrderModel?> getOrderById(int id) async {
    try {
      final result = await _db.getOrderById(id);
      return result != null ? OrderModel.fromMap(result) : null;
    } catch (e) {
      throw Exception('Error al obtener pedido: $e');
    }
  }

  /// Obtiene pedidos de un cliente.
  Future<List<OrderModel>> getOrdersByClient(int clientId) async {
    try {
      final results = await _db.getOrdersByClient(clientId);
      return results.map((map) => OrderModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos del cliente: $e');
    }
  }

  /// Obtiene pedidos por estado.
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    try {
      final all = await getAllOrders();
      return all.where((o) => o.status.value == status).toList();
    } catch (e) {
      throw Exception('Error al obtener pedidos por estado: $e');
    }
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Crea un nuevo pedido.
  Future<int> createOrder(OrderModel order) async {
    try {
      if (order.clientId == null || order.clientId == 0) {
        throw Exception('El pedido debe tener un ID de cliente');
      }
      final id = await _db.addOrder(
        order.clientId!,
        order.totalPrice,
        status: order.status.value,
      );
      return id;
    } catch (e) {
      throw Exception('Error al crear pedido: $e');
    }
  }

  /// Actualiza el estado de un pedido.
  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    try {
      await _db.updateOrderStatus(orderId, status.value);
    } catch (e) {
      throw Exception('Error al actualizar estado del pedido: $e');
    }
  }

  /// Elimina un pedido.
  Future<void> deleteOrder(int id) async {
    try {
      await _db.deleteOrder(id);
    } catch (e) {
      throw Exception('Error al eliminar pedido: $e');
    }
  }

  /// Agrega un ítem al pedido.
  Future<int> addOrderItem(
    int orderId,
    int productId,
    String productName,
    int quantity,
    double unitPrice,
  ) async {
    try {
      return await _db.addOrderItem(
        orderId,
        productId,
        productName,
        quantity,
        unitPrice,
      );
    } catch (e) {
      throw Exception('Error al agregar ítem al pedido: $e');
    }
  }

  /// Obtiene los ítems de un pedido.
  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    try {
      return await _db.getOrderItems(orderId);
    } catch (e) {
      throw Exception('Error al obtener ítems del pedido: $e');
    }
  }

  /// Elimina un ítem del pedido.
  Future<void> deleteOrderItem(int itemId) async {
    try {
      await _db.deleteOrderItem(itemId);
    } catch (e) {
      throw Exception('Error al eliminar ítem del pedido: $e');
    }
  }
}
