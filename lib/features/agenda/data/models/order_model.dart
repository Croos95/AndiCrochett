import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum OrderStatus { pending, inProgress, completed, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'Pendiente',
    OrderStatus.inProgress => 'En proceso',
    OrderStatus.completed => 'Completado',
    OrderStatus.cancelled => 'Cancelado',
  };

  String get firestoreValue => switch (this) {
    OrderStatus.pending => 'pending',
    OrderStatus.inProgress => 'in_progress',
    OrderStatus.completed => 'completed',
    OrderStatus.cancelled => 'cancelled',
  };

  static OrderStatus fromString(String v) => switch (v) {
    'in_progress' => OrderStatus.inProgress,
    'completed' => OrderStatus.completed,
    'cancelled' => OrderStatus.cancelled,
    _ => OrderStatus.pending,
  };
}

/// Ítem individual dentro de un pedido.
@immutable
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  double get subtotal => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    productId: m['productId'] as String? ?? '',
    productName: m['productName'] as String? ?? '',
    quantity: (m['quantity'] as num?)?.toInt() ?? 0,
    unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
  );
}

/// Pedido completo de un cliente.
@immutable
class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerContact,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.dueDate,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String customerName;
  final String customerContact;
  final List<OrderItem> items;
  final double totalPrice;
  final OrderStatus status;
  final DateTime dueDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'customerName': customerName,
    'customerContact': customerContact,
    'items': items.map((i) => i.toMap()).toList(),
    'totalPrice': totalPrice,
    'status': status.firestoreValue,
    'dueDate': Timestamp.fromDate(dueDate),
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawItems = d['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? '',
      customerContact: d['customerContact'] as String? ?? '',
      items: rawItems
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalPrice: (d['totalPrice'] as num?)?.toDouble() ?? 0,
      status: OrderStatusX.fromString(d['status'] as String? ?? ''),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: d['notes'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory OrderModel.empty({required String userId}) => OrderModel(
    id: '',
    userId: userId,
    customerName: '',
    customerContact: '',
    items: const [],
    totalPrice: 0,
    status: OrderStatus.pending,
    dueDate: DateTime.now().add(const Duration(days: 7)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerContact,
    List<OrderItem>? items,
    double? totalPrice,
    OrderStatus? status,
    DateTime? dueDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => OrderModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    customerName: customerName ?? this.customerName,
    customerContact: customerContact ?? this.customerContact,
    items: items ?? this.items,
    totalPrice: totalPrice ?? this.totalPrice,
    status: status ?? this.status,
    dueDate: dueDate ?? this.dueDate,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
