import 'dart:async';

import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';

/// Repositorio de Pedidos: Actúa como mediador entre la UI y la Base de Datos.
class OrderRepository {
  OrderRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;
  final _ordersStreamController = StreamController<List<OrderModel>>.broadcast();
  final DatabaseHelper _db;
  // Agregamos un controlador para notificar cambios
  
  Stream<List<OrderModel>> get ordersStream => _ordersStreamController.stream;
  // ── Lectura ───────────────────────────────────────────────────────────────
  /// Llamar a este método para refrescar la UI de la agenda
  Future<void> refreshOrders() async {
    final orders = await getAllOrders();
    _ordersStreamController.add(orders);
  }
  /// Obtiene todos los pedidos con sus ítems y nombre de cliente.
  Future<List<OrderModel>> getAllOrders() async {
    try {
      // Llamamos al método del DB Helper que ya hace el JOIN y trae los ítems
      return await _db.getAllOrdersWithItems();
    } catch (e) {
      throw Exception('Error al obtener la lista de pedidos: $e');
    }
  }

  /// Obtiene un pedido específico por su ID.
  Future<OrderModel?> getOrderById(int id) async {
    try {
      return await _db.getOrderById(id);
    } catch (e) {
      throw Exception('Error al obtener el pedido #$id: $e');
    }
  }

  /// Obtiene pedidos filtrados por usuario como Stream.
  Stream<List<OrderModel>> watchByUser(String userId) async* {
    // Primero obtener datos iniciales
    try {
      final initial = await _fetchOrdersByUser(userId);
      yield initial;
    } catch (e) {
      print('Error al cargar pedidos iniciales: $e');
    }
    
    // Luego escuchar cambios en el stream
    await for (final orders in _ordersStreamController.stream) {
      yield orders.where((o) => o.userId == userId).toList();
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

  /// Obtiene pedidos filtrados por cliente.
  Future<List<OrderModel>> getOrdersByClient(int clientId) async {
    try {
      // Nota: Aquí podrías filtrar la lista de getAllOrders() 
      // o crear un método específico en DB Helper si tienes miles de pedidos.
      final all = await _db.getAllOrdersWithItems();
     return all.where((o) => o.clientId == clientId).toList();
    } catch (e) {
      throw Exception('Error al filtrar pedidos por cliente: $e');
    }
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Crea un nuevo pedido.
  Future<void> create(OrderModel order) async {
    try {
      if (order.userId.isEmpty) {
        throw Exception('El pedido debe tener un usuario válido.');
      }
      await _db.createOrderFull(order);
      await refreshOrders();
    } catch (e) {
      throw Exception('Error al crear el pedido: $e');
    }
  }

  /// Actualiza un pedido existente.
  Future<void> update(OrderModel order) async {
    try {
      if (order.id == null) {
        throw Exception('No se puede actualizar un pedido sin ID.');
      }
      await _db.updateOrder(order);
      await refreshOrders();
    } catch (e) {
      throw Exception('Error al actualizar el pedido: $e');
    }
  }



  /// Actualiza solo el estado del pedido (ej: de Pendiente a Completado).
  Future<void> updateStatus(int orderId, OrderStatus status) async {
    try {
      await _db.updateOrderStatus(orderId, status.value);
      await refreshOrders(); // Refrescamos la agenda después de crear el pedido
    } catch (e) {
      throw Exception('Error al cambiar el estado del pedido: $e');
    }
  }
  // Devuelve los pedidos pendientes o en progreso (ideal para la pestaña Agenda)
  Future<List<OrderModel>> getActiveOrders() async {
    try {
      final all = await _db.getAllOrdersWithItems();
      // Filtramos solo los que no están completados ni cancelados
      return all.where((o) => 
        o.status == OrderStatus.pending || 
        o.status == OrderStatus.inProgress
      ).toList();
    } catch (e) {
      throw Exception('Error al cargar la agenda: $e');
    }
  }
  /// Filtra pedidos por un estado específico
  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status) async {
    try {
      final all = await _db.getAllOrdersWithItems();
      return all.where((o) => o.status == status).toList();
    } catch (e) {
      throw Exception('Error al filtrar pedidos: $e');
    }
  }
  /// Método rápido para completar desde la agenda
  Future<void> completeOrder(int id) async {
    await updateStatus(id, OrderStatus.completed);
  }
  /// Elimina un pedido y devuelve los productos al inventario.
  Future<void> delete(int id) async {
    try {
      // Usamos el método que revierte el stock para no perder inventario
      await _db.cancelAndReturnStock(id);
      await refreshOrders();
    } catch (e) {
      throw Exception('Error al cancelar el pedido: $e');
    }
  }


}