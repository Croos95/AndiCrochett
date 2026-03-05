// =============================================================================
//  ProductModel
//  DTO de Firestore para un producto del inventario en 'products'.
//
//  Esquema esperado (ver datos sembrados en _FirebaseTestView):
//    userId        String
//    name          String
//    imageUrl      String
//    category      String  (Lana | Hilo | Herramientas | Accesorio | ...)
//    color         String  (código hex)
//    weight        String  (p. ej. '100g')
//    currentStock  int
//    totalStock    int
//    status        String  (available | low_stock | out_of_stock)
//    isPublic      bool
//    createdAt     Timestamp
//    updatedAt     Timestamp
//
//  Estado: PENDIENTE DE IMPLEMENTACIÓN.
//  La UI de inventario (inventory_page.dart) actualmente usa datos estáticos;
//  este modelo y su repositorio conectarán la pantalla a Firestore.
// =============================================================================

import 'package:flutter/foundation.dart';

enum ProductStatus { available, lowStock, outOfStock }

extension ProductStatusX on ProductStatus {
  String get label => switch (this) {
    ProductStatus.available => 'Disponible',
    ProductStatus.lowStock => 'Bajo stock',
    ProductStatus.outOfStock => 'Sin existencias',
  };

  static ProductStatus fromString(String v) => switch (v) {
    'low_stock' => ProductStatus.lowStock,
    'out_of_stock' => ProductStatus.outOfStock,
    _ => ProductStatus.available,
  };
}

/// Producto del inv ntario.
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
  final int currentStock;
  final int totalStock;
  final ProductStatus status;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  // TODO: Implementar toMap(), fromDoc(), copyWith().
}
