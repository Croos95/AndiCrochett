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

  String get value => switch (this) {
    OrderStatus.pending => 'pending',
    OrderStatus.inProgress => 'in_progress',
    OrderStatus.completed => 'completed',
    OrderStatus.cancelled => 'cancelled',
  };

  String get firestoreValue => value; // Compatibilidad con código existente

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

/// Pedido completo (compatible con Firestore y SQLite)
@immutable
class OrderModel {
  const OrderModel({
    // ── Campos para Firestore ──
    this.id,
    this.userId = '',
    this.customerName = '',
    this.customerContact = '',
    this.dueDate,
    this.updatedAt,
    this.items = const [],
    // ── Campos para SQLite ──
    this.clientId = 0,
    this.clientName = '',
    this.clientEmail = '',
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.notes = '',
  });

  // ── Campos para Firestore ──
  final String? id; // ID de Firestore (string)
  final String userId;
  final String customerName;
  final String customerContact;
  final DateTime? dueDate;
  final DateTime? updatedAt;
  final List<OrderItem> items;
  
  // ── Campos para SQLite ──
  final int? clientId; // ID de SQLite (int)
  final String clientName;
  final String clientEmail;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final String notes;

  // ── Serialización para SQLite ─────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': _parseIdToInt(id),
    'cliente_id': clientId,
    'nombre_cliente': customerName.isNotEmpty ? customerName : clientName,
    'email_cliente': clientEmail,
    'total': totalPrice,
    'estado': status.value,
    'fecha_pedido': createdAt.toIso8601String(),
    'notas': notes,
  };

  /// Convierte desde Map de SQLite a OrderModel
  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
    id: map['id']?.toString(),
    clientId: (map['cliente_id'] as num?)?.toInt() ?? 0,
    customerName: map['nombre_cliente'] as String? ?? '',
    clientName: map['nombre_cliente'] as String? ?? '',
    clientEmail: map['email_cliente'] as String? ?? '',
    totalPrice: (map['total'] as num?)?.toDouble() ?? 0.0,
    status: OrderStatusX.fromString(map['estado'] as String? ?? 'pending'),
    createdAt: map['fecha_pedido'] != null
        ? DateTime.tryParse(map['fecha_pedido'] as String) ?? DateTime.now()
        : DateTime.now(),
    notes: map['notas'] as String? ?? '',
  );

  /// Soporte para Firestore
  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawItems = d['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? '',
      customerContact: d['customerContact'] as String? ?? '',
      totalPrice: (d['totalPrice'] as num?)?.toDouble() ?? 0,
      status: OrderStatusX.fromString(d['status'] as String? ?? ''),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      items: rawItems
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      notes: d['notes'] as String? ?? '',
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toFirestoreMap() => {
    'userId': userId,
    'customerName': customerName,
    'customerContact': customerContact,
    'items': items.map((i) => i.toMap()).toList(),
    'totalPrice': totalPrice,
    'status': status.firestoreValue,
    'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : Timestamp.fromDate(DateTime.now()),
  };

  factory OrderModel.empty({String? userId}) => OrderModel(
    userId: userId ?? '',
    totalPrice: 0,
    status: OrderStatus.pending,
    createdAt: DateTime.now(),
    dueDate: DateTime.now().add(const Duration(days: 7)),
  );

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerContact,
    int? clientId,
    String? clientName,
    String? clientEmail,
    List<OrderItem>? items,
    double? totalPrice,
    OrderStatus? status,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) =>
      OrderModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        customerName: customerName ?? this.customerName,
        customerContact: customerContact ?? this.customerContact,
        clientId: clientId ?? this.clientId,
        clientName: clientName ?? this.clientName,
        clientEmail: clientEmail ?? this.clientEmail,
        items: items ?? this.items,
        totalPrice: totalPrice ?? this.totalPrice,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        notes: notes ?? this.notes,
      );

  /// Convierte id string a int si es posible
  static int? _parseIdToInt(String? id) {
    if (id == null) return null;
    try {
      return int.parse(id);
    } catch (_) {
      return null;
    }
  }
}
