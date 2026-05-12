// lib/features/analytics/data/analytics_repository.dart
//
// Calcula métricas agregadas a partir de los datos locales (SQLite) y
// las devuelve listas para renderizar en el dashboard. Toda la lógica SQL
// vive aquí — el widget de UI no sabe nada de tablas ni columnas.
//
// Las queries son intencionalmente simples (COUNT, SUM, GROUP BY) para
// que el costo sea despreciable incluso sin índices.

import 'package:andicrochett/database_helper.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';
import 'package:andicrochett/features/analytics/data/models/dashboard_metrics.dart';
import 'package:sqflite/sqflite.dart';

class AnalyticsRepository {
  AnalyticsRepository({DatabaseHelper? dbHelper})
      : _db = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  /// Punto de entrada — calcula todas las métricas y las devuelve en un solo
  /// DTO. El widget hace un único `FutureBuilder` y renderiza.
  Future<DashboardMetrics> loadDashboard() async {
    final db = await _db.database;

    final results = await Future.wait([
      _countProducts(db),
      _countProductsByStatus(db, 'low_stock'),
      _countProductsByStatus(db, 'out_of_stock'),
      _countOrders(db),
      _countClients(db),
      _revenueLast30Days(db),
      _ordersByStatus(db),
      _topProducts(db),
    ]);

    return DashboardMetrics(
      totalProducts: results[0] as int,
      lowStockCount: results[1] as int,
      outOfStockCount: results[2] as int,
      totalOrders: results[3] as int,
      totalClients: results[4] as int,
      revenueLast30Days: results[5] as double,
      ordersByStatus: results[6] as List<StatusBreakdown>,
      topProducts: results[7] as List<TopProduct>,
    );
  }

  // ── Queries ─────────────────────────────────────────────────────────────────

  Future<int> _countProducts(Database db) async {
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tableProducts}');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> _countProductsByStatus(Database db, String status) async {
    final r = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${DatabaseHelper.tableProducts} WHERE ${DatabaseHelper.productStatus} = ?',
      [status],
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> _countOrders(Database db) async {
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tableOrders}');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> _countClients(Database db) async {
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM ${DatabaseHelper.tableClients}');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<double> _revenueLast30Days(Database db) async {
    // Suma del total de pedidos completados en los últimos 30 días.
    final cutoff = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final r = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(${DatabaseHelper.orderTotal}), 0) as total
      FROM ${DatabaseHelper.tableOrders}
      WHERE ${DatabaseHelper.orderStatus} = 'completed'
        AND ${DatabaseHelper.orderDate} >= ?
      ''',
      [cutoff],
    );
    final value = r.first['total'];
    return (value is num) ? value.toDouble() : 0.0;
  }

  Future<List<StatusBreakdown>> _ordersByStatus(Database db) async {
    final rows = await db.rawQuery('''
      SELECT ${DatabaseHelper.orderStatus} as status, COUNT(*) as c
      FROM ${DatabaseHelper.tableOrders}
      GROUP BY ${DatabaseHelper.orderStatus}
      ORDER BY c DESC
    ''');

    return rows.map((m) {
      final key = (m['status'] as String?) ?? 'pending';
      final status = OrderStatusX.fromString(key);
      return StatusBreakdown(
        statusKey: key,
        label: status.label,
        count: (m['c'] as int?) ?? 0,
      );
    }).toList();
  }

  Future<List<TopProduct>> _topProducts(Database db) async {
    // Top 5 productos por unidades vendidas usando items_pedido.
    final rows = await db.rawQuery('''
      SELECT ${DatabaseHelper.orderItemProductName} as nombre,
             SUM(${DatabaseHelper.orderItemQuantity}) as units,
             SUM(${DatabaseHelper.orderItemQuantity} * ${DatabaseHelper.orderItemUnitPrice}) as revenue
      FROM ${DatabaseHelper.tableOrderItems}
      GROUP BY ${DatabaseHelper.orderItemProductName}
      ORDER BY units DESC
      LIMIT 5
    ''');

    return rows.map((m) {
      return TopProduct(
        name: (m['nombre'] as String?) ?? '',
        unitsSold: ((m['units'] as num?) ?? 0).toInt(),
        revenue: ((m['revenue'] as num?) ?? 0).toDouble(),
      );
    }).toList();
  }
}
