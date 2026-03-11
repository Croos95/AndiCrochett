import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ProductStatus { available, lowStock, outOfStock }

extension ProductStatusX on ProductStatus {
  String get label => switch (this) {
    ProductStatus.available => 'Disponible',
    ProductStatus.lowStock => 'Bajo stock',
    ProductStatus.outOfStock => 'Sin existencias',
  };

  String get firestoreValue => switch (this) {
    ProductStatus.available => 'available',
    ProductStatus.lowStock => 'low_stock',
    ProductStatus.outOfStock => 'out_of_stock',
  };

  static ProductStatus fromString(String v) => switch (v) {
    'low_stock' => ProductStatus.lowStock,
    'out_of_stock' => ProductStatus.outOfStock,
    _ => ProductStatus.available,
  };
}

/// Producto del inventario.
@immutable
class ProductModel {
  const ProductModel({
    required this.id,
    required this.userId,
    required this.name,
    this.imageUrl = '',
    required this.category,
    this.color = '',
    this.weight = '',
    this.brand = '',
    required this.currentStock,
    required this.totalStock,
    required this.status,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String imageUrl;
  final String category;
  final String color;
  final String weight;
  final String brand;
  final int currentStock;
  final int totalStock;
  final ProductStatus status;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'imageUrl': imageUrl,
    'category': category,
    'color': color,
    'weight': weight,
    'brand': brand,
    'currentStock': currentStock,
    'totalStock': totalStock,
    'status': status.firestoreValue,
    'isPublic': isPublic,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory ProductModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      imageUrl: d['imageUrl'] as String? ?? '',
      category: d['category'] as String? ?? '',
      color: d['color'] as String? ?? '',
      weight: d['weight'] as String? ?? '',
      brand: d['brand'] as String? ?? '',
      currentStock: (d['currentStock'] as num?)?.toInt() ?? 0,
      totalStock: (d['totalStock'] as num?)?.toInt() ?? 0,
      status: ProductStatusX.fromString(d['status'] as String? ?? ''),
      isPublic: d['isPublic'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ProductModel.empty({required String userId}) => ProductModel(
    id: '',
    userId: userId,
    name: '',
    category: 'Lana',
    currentStock: 0,
    totalStock: 0,
    status: ProductStatus.available,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  ProductModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? imageUrl,
    String? category,
    String? color,
    String? weight,
    String? brand,
    int? currentStock,
    int? totalStock,
    ProductStatus? status,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProductModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    imageUrl: imageUrl ?? this.imageUrl,
    category: category ?? this.category,
    color: color ?? this.color,
    weight: weight ?? this.weight,
    brand: brand ?? this.brand,
    currentStock: currentStock ?? this.currentStock,
    totalStock: totalStock ?? this.totalStock,
    status: status ?? this.status,
    isPublic: isPublic ?? this.isPublic,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
