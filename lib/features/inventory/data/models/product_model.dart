import 'package:flutter/foundation.dart';
//lib/features/inventory/data/models/product_model.dart
enum ProductStatus { available, lowStock, outOfStock }

extension ProductStatusX on ProductStatus {
  String get label => switch (this) {
    ProductStatus.available => 'Disponible',
    ProductStatus.lowStock => 'Bajo stock',
    ProductStatus.outOfStock => 'Sin existencias',
  };

  String get sqliteValue => switch (this) {
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

/// Producto del inventario (optimizado para SQLite).
@immutable
class ProductModel {
  const ProductModel({
    this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.imageUrl = '',
    this.category = '',
    this.color = '',
    this.weight = '',
    this.brand = '',
    required this.currentStock,
    this.status = ProductStatus.available,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String color;
  final String weight;
  final String brand;
  final int currentStock;
  final ProductStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── Métodos de copia ──────────────────────────────────────────────────────

  ProductModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    String? color,
    String? weight,
    String? brand,
    int? currentStock,
    ProductStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ProductModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        imageUrl: imageUrl ?? this.imageUrl,
        category: category ?? this.category,
        color: color ?? this.color,
        weight: weight ?? this.weight,
        brand: brand ?? this.brand,
        currentStock: currentStock ?? this.currentStock,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  // ── Serialización para SQLite ─────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nombre': name,
    'descripcion': description,
    'precio': price,
    'imagen': imageUrl,
    'categoria': category,
    'color': color,
    'peso': weight,
    'marca': brand,
    'cantidad': currentStock,
    'estado': status.sqliteValue,
    'fecha_creacion': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'fecha_actualizacion': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
  };

  /// Convierte desde Map de SQLite a ProductModel
  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
    id: map['id'] as int?,
    name: map['nombre'] as String? ?? '',
    description: map['descripcion'] as String? ?? '',
    price: (map['precio'] as num?)?.toDouble() ?? 0.0,
    imageUrl: map['imagen'] as String? ?? '',
    category: map['categoria'] as String? ?? '',
    color: map['color'] as String? ?? '',
    weight: map['peso'] as String? ?? '',
    brand: map['marca'] as String? ?? '',
    currentStock: (map['cantidad'] as num?)?.toInt() ?? 0,
    status: ProductStatusX.fromString(map['estado'] as String? ?? 'available'),
    createdAt: map['fecha_creacion'] != null
        ? DateTime.tryParse(map['fecha_creacion'] as String)
        : null,
    updatedAt: map['fecha_actualizacion'] != null
        ? DateTime.tryParse(map['fecha_actualizacion'] as String)
        : null,
  );

  factory ProductModel.empty() => const ProductModel(
    name: '',
    price: 0.0,
    currentStock: 0,
  );
}