import 'package:andicrochett/core/config/env.dart';
import 'package:andicrochett/core/services/api_client.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';

/// Repositorio de Pedidos contra la API REST.
///
/// Los datos son compartidos entre usuarios autenticados. `watchByUser` se
/// mantiene por compatibilidad de firma pero devuelve todos los pedidos.
class OrderRepository {
  OrderRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  static const _basePath = '/orders';

  // ── Streams (polling con Env.pollInterval) ───────────────────────────────

  Stream<List<OrderModel>> watchByUser(String _) async* {
    yield await getAllOrders();
    yield* _refresh(getAllOrders);
  }

  Stream<T> _refresh<T>(Future<T> Function() fetch) async* {
    while (true) {
      await Future.delayed(Env.pollInterval);
      yield await fetch();
    }
  }

  // ── Lectura ───────────────────────────────────────────────────────────────

  Future<List<OrderModel>> getAllOrders() async {
    final data = await _api.get(_basePath) as List<dynamic>;
    return data.map(_orderFromJson).toList();
  }

  Future<OrderModel?> getOrderById(int id) async {
    try {
      final data = await _api.get('$_basePath/$id') as Map<String, dynamic>;
      return _orderFromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<OrderModel>> getOrdersByClient(int clientId) async {
    final all = await getAllOrders();
    return all.where((o) => o.clientId == clientId).toList();
  }

  Future<List<OrderModel>> getActiveOrders() async {
    final all = await getAllOrders();
    return all
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.inProgress)
        .toList();
  }

  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status) async {
    final all = await getAllOrders();
    return all.where((o) => o.status == status).toList();
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  Future<void> create(OrderModel order) async {
    await _api.post(_basePath, body: _toBody(order));
  }

  Future<void> update(OrderModel order) async {
    if (order.id == null) throw Exception('No se puede actualizar un pedido sin ID.');
    await _api.put('$_basePath/${order.id}', body: _toBody(order));
  }

  Future<void> updateStatus(int orderId, OrderStatus status) async {
    await _api.patch('$_basePath/$orderId/status', body: {'estado': status.value});
  }

  Future<void> completeOrder(int id) => updateStatus(id, OrderStatus.completed);

  /// Cancela el pedido y devuelve el stock al inventario (transacción en el backend).
  /// Mantenemos el nombre `delete` por compatibilidad con las páginas existentes.
  Future<void> delete(int id) async {
    await _api.post('$_basePath/$id/cancel');
  }

  void dispose() {}

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toBody(OrderModel o) => {
    'cliente_id': o.clientId,
    'nombre_cliente': o.clientName,
    'contacto_cliente': o.customerContact,
    'total': o.totalPrice,
    'estado': o.status.value,
    'fecha_entrega': o.dueDate?.toIso8601String(),
    'notas': o.notes,
    'items': o.items.map((i) => i.toMap()).toList(),
  };

  OrderModel _orderFromJson(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final rawItems = (map['items'] as List?) ?? const [];
    final items = rawItems
        .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
        .toList();
    return OrderModel.fromMap(map, items: items);
  }
}
