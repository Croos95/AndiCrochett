// test/unit/analytics/analytics_repository_test.dart
//
// Pruebas de integración del AnalyticsRepository contra SQLite real. Inserta
// datos seed, llama a loadDashboard() y verifica los agregados.

import 'dart:io';

import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';
import 'package:andicrochett/features/analytics/data/analytics_repository.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper.instance.closeDatabase();
    final dbPath = p.join(await getDatabasesPath(), 'andicrochett.db');
    final f = File(dbPath);
    if (await f.exists()) await f.delete();
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.closeDatabase();
    final dbPath = p.join(await getDatabasesPath(), 'andicrochett.db');
    final f = File(dbPath);
    if (await f.exists()) await f.delete();
  });

  group('AnalyticsRepository.loadDashboard', () {
    test('reporta ceros cuando la BD está vacía', () async {
      final m = await AnalyticsRepository().loadDashboard();

      expect(m.totalProducts, 0);
      expect(m.totalOrders, 0);
      expect(m.totalClients, 0);
      expect(m.revenueLast30Days, 0.0);
      expect(m.ordersByStatus, isEmpty);
      expect(m.topProducts, isEmpty);
    });

    test('cuenta productos por estado correctamente', () async {
      await DatabaseHelper.instance.addProduct(
        const ProductModel(name: 'OK', price: 1, currentStock: 10).toMap(),
      );
      await DatabaseHelper.instance.addProduct(
        const ProductModel(
          name: 'Bajo',
          price: 1,
          currentStock: 1,
          status: ProductStatus.lowStock,
        ).toMap(),
      );
      await DatabaseHelper.instance.addProduct(
        const ProductModel(
          name: 'Sin',
          price: 1,
          currentStock: 0,
          status: ProductStatus.outOfStock,
        ).toMap(),
      );

      final m = await AnalyticsRepository().loadDashboard();
      expect(m.totalProducts, 3);
      expect(m.lowStockCount, 1);
      expect(m.outOfStockCount, 1);
    });

    test('agrega ingresos solo de pedidos completados recientes', () async {
      final now = DateTime.now();

      await DatabaseHelper.instance.createOrderFull(
        OrderModel(
          userId: 'u',
          totalPrice: 100,
          status: OrderStatus.completed,
          createdAt: now,
        ),
      );
      await DatabaseHelper.instance.createOrderFull(
        OrderModel(
          userId: 'u',
          totalPrice: 200,
          status: OrderStatus.pending, // no cuenta
          createdAt: now,
        ),
      );
      await DatabaseHelper.instance.createOrderFull(
        OrderModel(
          userId: 'u',
          totalPrice: 999,
          status: OrderStatus.completed,
          createdAt: now.subtract(const Duration(days: 60)), // fuera de ventana
        ),
      );

      final m = await AnalyticsRepository().loadDashboard();
      expect(m.revenueLast30Days, 100.0);
      expect(m.totalOrders, 3);
    });

    test('agrupa pedidos por estado y los devuelve ordenados', () async {
      final now = DateTime.now();
      for (var i = 0; i < 3; i++) {
        await DatabaseHelper.instance.createOrderFull(
          OrderModel(
            userId: 'u',
            totalPrice: 1,
            status: OrderStatus.pending,
            createdAt: now,
          ),
        );
      }
      await DatabaseHelper.instance.createOrderFull(
        OrderModel(
          userId: 'u',
          totalPrice: 1,
          status: OrderStatus.completed,
          createdAt: now,
        ),
      );

      final m = await AnalyticsRepository().loadDashboard();
      expect(m.ordersByStatus, hasLength(2));
      expect(m.ordersByStatus.first.statusKey, 'pending');
      expect(m.ordersByStatus.first.count, 3);
    });

    test('top productos respeta unidades vendidas', () async {
      // items_pedido.producto_id es NOT NULL — sembramos productos primero.
      final gorroId = await DatabaseHelper.instance.addProduct(
        const ProductModel(name: 'Gorro', price: 100, currentStock: 100).toMap(),
      );
      final bufandaId = await DatabaseHelper.instance.addProduct(
        const ProductModel(name: 'Bufanda', price: 200, currentStock: 100).toMap(),
      );

      final now = DateTime.now();
      await DatabaseHelper.instance.createOrderFull(
        OrderModel(
          userId: 'u',
          totalPrice: 0,
          status: OrderStatus.completed,
          createdAt: now,
          items: [
            OrderItem(productId: gorroId, productName: 'Gorro', quantity: 10, unitPrice: 100),
            OrderItem(productId: bufandaId, productName: 'Bufanda', quantity: 3, unitPrice: 200),
          ],
        ),
      );

      final m = await AnalyticsRepository().loadDashboard();
      expect(m.topProducts, hasLength(2));
      expect(m.topProducts.first.name, 'Gorro');
      expect(m.topProducts.first.unitsSold, 10);
      expect(m.topProducts.first.revenue, 1000.0);
    });
  });
}
