// test/unit/models/product_model_test.dart
//
// Pruebas unitarias del modelo de producto. Validan la serialización
// hacia/desde SQLite y el comportamiento del enum ProductStatus.
// No tocan base de datos ni red — son puramente lógica de dominio.

import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductStatusX', () {
    test('fromString reconoce los valores SQLite', () {
      expect(ProductStatusX.fromString('available'), ProductStatus.available);
      expect(ProductStatusX.fromString('low_stock'), ProductStatus.lowStock);
      expect(
        ProductStatusX.fromString('out_of_stock'),
        ProductStatus.outOfStock,
      );
    });

    test('fromString cae en available cuando recibe basura', () {
      expect(ProductStatusX.fromString('xxx'), ProductStatus.available);
      expect(ProductStatusX.fromString(''), ProductStatus.available);
    });

    test('sqliteValue es estable (contrato con la BD)', () {
      expect(ProductStatus.available.sqliteValue, 'available');
      expect(ProductStatus.lowStock.sqliteValue, 'low_stock');
      expect(ProductStatus.outOfStock.sqliteValue, 'out_of_stock');
    });
  });

  group('ProductModel', () {
    test('toMap/fromMap es round-trip', () {
      final original = ProductModel(
        id: 7,
        name: 'Estambre rojo',
        description: 'Lana mediana',
        price: 149.99,
        imageUrl: 'http://img/a.png',
        category: 'Estambres',
        color: 'rojo',
        weight: 'medium',
        brand: 'Omega',
        currentStock: 12,
        status: ProductStatus.lowStock,
        createdAt: DateTime.utc(2026, 1, 1, 10),
        updatedAt: DateTime.utc(2026, 1, 2, 11),
      );

      final restored = ProductModel.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.price, original.price);
      expect(restored.currentStock, original.currentStock);
      expect(restored.status, ProductStatus.lowStock);
      expect(restored.category, 'Estambres');
    });

    test('copyWith solo modifica los campos pasados', () {
      final base = ProductModel.empty().copyWith(
        name: 'A',
        price: 10,
        currentStock: 5,
      );

      final next = base.copyWith(
        currentStock: 0,
        status: ProductStatus.outOfStock,
      );

      expect(next.name, 'A');
      expect(next.price, 10);
      expect(next.currentStock, 0);
      expect(next.status, ProductStatus.outOfStock);
    });

    test('fromMap tolera Map con campos faltantes', () {
      final restored = ProductModel.fromMap({'nombre': 'Solo nombre'});
      expect(restored.name, 'Solo nombre');
      expect(restored.price, 0.0);
      expect(restored.currentStock, 0);
      expect(restored.status, ProductStatus.available);
    });
  });
}
