import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';
import 'package:andicrochett/features/agenda/data/repositories/agenda_repository.dart';

enum AgendaStatus { initial, loading, loaded, error }

/// ChangeNotifier para la gestión del estado de la agenda de pedidos.
class AgendaProvider extends ChangeNotifier {
  AgendaProvider({
    required String userId,
    AgendaRepository? repository,
  })  : _userId = userId,
        _repo = repository ?? AgendaRepository() {
    _init();
  }

  final String _userId;
  final AgendaRepository _repo;
  StreamSubscription<List<OrderModel>>? _sub;

  AgendaStatus _status = AgendaStatus.initial;
  AgendaStatus get status => _status;

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  String? _error;
  String? get error => _error;

  // ── Getters de conveniencia ────────────────────────────────────────────

  List<OrderModel> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();

  List<OrderModel> get inProgressOrders =>
      _orders.where((o) => o.status == OrderStatus.inProgress).toList();

  List<OrderModel> get completedOrders =>
      _orders.where((o) => o.status == OrderStatus.completed).toList();

  /// Pedidos con fecha de entrega para un día específico.
  List<OrderModel> ordersForDay(DateTime day) {
    return _orders.where((o) {
      final dueDate = o.dueDate ?? o.createdAt;
      return dueDate.year == day.year &&
          dueDate.month == day.month &&
          dueDate.day == day.day;
    }).toList();
  }

  // ── Inicialización ────────────────────────────────────────────────────────

  void _init() {
    _status = AgendaStatus.loading;
    notifyListeners();

    _sub = _repo.watchByUser(_userId).listen(
      (data) {
        _orders = data;
        _status = AgendaStatus.loaded;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _status = AgendaStatus.error;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  // ── Operaciones CRUD ──────────────────────────────────────────────────────

  Future<String> createOrder(OrderModel order) async {
    return _repo.create(order.copyWith(userId: _userId));
  }

  Future<void> updateOrder(OrderModel order) async {
    await _repo.update(order);
  }

  Future<void> deleteOrder(String id) async {
    await _repo.delete(id);
  }

  Future<void> updateStatus(String id, OrderStatus status) async {
    await _repo.updateStatus(id, status);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
