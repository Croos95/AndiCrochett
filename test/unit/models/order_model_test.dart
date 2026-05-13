// test/unit/models/order_model_test.dart
//
// Pruebas unitarias del pedido (OrderModel) y sus ítems (OrderItem).
// Verifican subtotales, round-trip de Map y el enum OrderStatus.

import 'package:andicrochett/features/agenda/data/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderStatusX', () {
    test('label devuelve textos en español', () {
      expect(OrderStatus.pending.label, 'Pendiente');
      expect(OrderStatus.inProgress.label, 'En proceso');
      expect(OrderStatus.completed.label, 'Completado');
      expect(OrderStatus.cancelled.label, 'Cancelado');
    });

    test('fromString reconoce valores válidos', () {
      expect(OrderStatusX.fromString('pending'), OrderStatus.pending);
      expect(OrderStatusX.fromString('inProgress'), OrderStatus.inProgress);
      expect(OrderStatusX.fromString('completed'), OrderStatus.completed);
    });

    test('fromString cae en pending si no reconoce', () {
      expect(OrderStatusX.fromString('???'), OrderStatus.pending);
    });
  });

  group('OrderItem', () {
    test('subtotal multiplica cantidad por precio', () {
      const item = OrderItem(
        productName: 'Bufanda',
        quantity: 3,
        unitPrice: 150.0,
      );
      expect(item.subtotal, 450.0);
    });

    test('toMap/fromMap es round-trip', () {
      const item = OrderItem(
        id: 1,
        productId: 9,
        productName: 'Gorrito',
        quantity: 2,
        unitPrice: 89.5,
      );

      final restored = OrderItem.fromMap(item.toMap());
      expect(restored.productName, 'Gorrito');
      expect(restored.quantity, 2);
      expect(restored.unitPrice, 89.5);
      expect(restored.subtotal, 179.0);
    });
  });

  group('OrderModel', () {
    test('toMap incluye los campos esperados', () {
      final order = OrderModel(
        userId: 'user-1',
        clientId: 5,
        clientName: 'Andrea',
        customerContact: '555-0000',
        totalPrice: 300.0,
        status: OrderStatus.inProgress,
        createdAt: DateTime.utc(2026, 5, 1),
        notes: 'Entregar viernes',
      );

      final map = order.toMap();

      expect(map['usuario_id'], 'user-1');
      expect(map['cliente_id'], 5);
      expect(map['nombre_cliente'], 'Andrea');
      expect(map['total'], 300.0);
      expect(map['estado'], 'inProgress');
      expect(map['notas'], 'Entregar viernes');
    });

    test('fromMap reconstruye items pasados aparte', () {
      final order = OrderModel.fromMap(
        {
          'id': 1,
          'usuario_id': 'u',
          'cliente_id': 0,
          'total': 200.0,
          'estado': 'completed',
          'fecha_pedido': DateTime.utc(2026, 5, 1).toIso8601String(),
        },
        items: const [OrderItem(productName: 'X', quantity: 2, unitPrice: 100)],
      );

      expect(order.id, 1);
      expect(order.status, OrderStatus.completed);
      expect(order.items, hasLength(1));
      expect(order.items.first.subtotal, 200);
    });

    test('copyWith reemplaza solo el status', () {
      final base = OrderModel(
        userId: 'u',
        totalPrice: 100,
        status: OrderStatus.pending,
        createdAt: DateTime.utc(2026, 5, 1),
      );

      final next = base.copyWith(status: OrderStatus.completed);
      expect(next.status, OrderStatus.completed);
      expect(next.totalPrice, 100);
      expect(next.userId, 'u');
    });
  });
}
