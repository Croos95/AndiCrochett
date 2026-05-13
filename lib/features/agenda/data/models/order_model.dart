import 'package:flutter/foundation.dart';

enum OrderStatus { pending, inProgress, completed, cancelled }

extension OrderStatusX on OrderStatus {
  String get value => name;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.inProgress:
        return 'En proceso';
      case OrderStatus.completed:
        return 'Completado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  static OrderStatus fromString(String v) => OrderStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => OrderStatus.pending,
  );
}

@immutable
class OrderItem {
  final int? id;
  final int? productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  // Cálculo del subtotal
  double get subtotal => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'producto_id': productId,
    'nombre_producto': productName,
    'cantidad': quantity,
    'precio_unitario': unitPrice,
  };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    id: m['id'],
    productId: m['producto_id'],
    productName: m['nombre_producto'] ?? '',
    quantity: m['cantidad'] ?? 0,
    unitPrice: (m['precio_unitario'] as num?)?.toDouble() ?? 0.0,
  );
}

@immutable
class OrderModel {
  final int? id;
  final String userId;
  final int clientId;
  final String clientName;
  final String customerContact;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String notes;
  final List<OrderItem> items;

  const OrderModel({
    this.id,
    required this.userId,
    this.clientId = 0,
    this.clientName = '',
    this.customerContact = '',
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.notes = '',
    this.items = const [],
  });

  OrderModel copyWith({
    int? id,
    String? userId,
    int? clientId,
    String? clientName,
    String? customerContact,
    double? totalPrice,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? dueDate,
    String? notes,
    List<OrderItem>? items,
  }) => OrderModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    clientId: clientId ?? this.clientId,
    clientName: clientName ?? this.clientName,
    customerContact: customerContact ?? this.customerContact,
    totalPrice: totalPrice ?? this.totalPrice,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    dueDate: dueDate ?? this.dueDate,
    notes: notes ?? this.notes,
    items: items ?? this.items,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'usuario_id': userId,
    'cliente_id': clientId,
    'nombre_cliente': clientName,
    'contacto_cliente': customerContact,
    'total': totalPrice,
    'estado': status.value,
    'fecha_pedido': createdAt.toIso8601String(),
    if (dueDate != null) 'fecha_entrega': dueDate!.toIso8601String(),
    'notas': notes,
  };

  factory OrderModel.fromMap(
    Map<String, dynamic> map, {
    List<OrderItem> items = const [],
  }) => OrderModel(
    id: map['id'],
    userId: map['usuario_id'] ?? '',
    clientId: map['cliente_id'] ?? 0,
    clientName: map['nombre_cliente'] ?? '',
    customerContact: map['contacto_cliente'] ?? '',
    totalPrice: (map['total'] as num?)?.toDouble() ?? 0.0,
    status: OrderStatusX.fromString(map['estado'] ?? 'pending'),
    createdAt: DateTime.tryParse(map['fecha_pedido'] ?? '') ?? DateTime.now(),
    dueDate: map['fecha_entrega'] != null
        ? DateTime.tryParse(map['fecha_entrega'])
        : null,
    notes: map['notas'] ?? '',
    items: items,
  );
}
