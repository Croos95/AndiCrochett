import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de un item dentro de un pedido.
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Modelo de pedido / orden para la agenda.
class OrderModel {
  final String id;
  final String userId;
  final String customerName;
  final String customerContact;
  final List<OrderItem> items;
  final double totalPrice;
  final String status; // pending | in_progress | completed | cancelled
  final DateTime? dueDate;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.customerName,
    this.customerContact = '',
    this.items = const [],
    this.totalPrice = 0,
    this.status = 'pending',
    this.dueDate,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  //  Helpers 

  String get statusLabel => switch (status) {
        'pending' => 'Pendiente',
        'in_progress' => 'En progreso',
        'completed' => 'Completado',
        'cancelled' => 'Cancelado',
        _ => status,
      };

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';

  //  Firestore serialization 

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'customerName': customerName,
        'customerContact': customerContact,
        'items': items.map((e) => e.toMap()).toList(),
        'totalPrice': totalPrice,
        'status': status,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'notes': notes,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerContact: map['customerContact'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      notes: map['notes'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory OrderModel.fromDocument(DocumentSnapshot doc) {
    return OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  //  copyWith 

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerContact,
    List<OrderItem>? items,
    double? totalPrice,
    String? status,
    DateTime? dueDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
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
}
