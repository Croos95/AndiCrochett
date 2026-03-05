// =============================================================================
//  OrderModel
//  DTO de Firestore para un pedido de cliente en la colección 'orders'.
//
//  Esquema esperado (ver datos sembrados en _FirebaseTestView):
//    userId          String
//    customerName    String
//    customerContact String
//    items           List<OrderItem>  (productId, productName, quantity, unitPrice)
//    totalPrice      double
//    status          String  (pending | in_progress | completed | cancelled)
//    dueDate         Timestamp
//    notes           String
//    createdAt       Timestamp
//    updatedAt       Timestamp
//
//  Estado: PENDIENTE DE IMPLEMENTACIÓN.
// =============================================================================

// ignore: unused_import — Timestamp se usará al implementar toMap/fromDoc
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

  static OrderStatus fromString(String v) => OrderStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => OrderStatus.pending,
  );
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

  // TODO: Implementar toMap() y fromMap().
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

  // TODO: Implementar toMap(), fromDoc(), copyWith().
}
