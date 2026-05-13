import 'package:andicrochett/core/services/api_client.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';
import 'package:andicrochett/features/analytics/data/models/dashboard_metrics.dart';

/// Repositorio de métricas del dashboard.
///
/// Consume `/api/analytics/dashboard` que calcula los agregados en el servidor
/// (counts, sums, group by) sobre la BD SQLite centralizada.
class AnalyticsRepository {
  AnalyticsRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<DashboardMetrics> loadDashboard() async {
    final data = await _api.get('/analytics/dashboard') as Map<String, dynamic>;

    final breakdowns = (data['ordersByStatus'] as List? ?? const [])
        .map((raw) {
          final m = raw as Map<String, dynamic>;
          final key = m['statusKey'] as String? ?? 'pending';
          final status = OrderStatusX.fromString(key);
          return StatusBreakdown(
            statusKey: key,
            label: status.label,
            count: (m['count'] as num?)?.toInt() ?? 0,
          );
        })
        .toList();

    final tops = (data['topProducts'] as List? ?? const [])
        .map((raw) {
          final m = raw as Map<String, dynamic>;
          return TopProduct(
            name: m['name'] as String? ?? '',
            unitsSold: (m['unitsSold'] as num?)?.toInt() ?? 0,
            revenue: (m['revenue'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList();

    return DashboardMetrics(
      totalProducts: (data['totalProducts'] as num?)?.toInt() ?? 0,
      lowStockCount: (data['lowStockCount'] as num?)?.toInt() ?? 0,
      outOfStockCount: (data['outOfStockCount'] as num?)?.toInt() ?? 0,
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
      totalClients: (data['totalClients'] as num?)?.toInt() ?? 0,
      revenueLast30Days: (data['revenueLast30Days'] as num?)?.toDouble() ?? 0,
      ordersByStatus: breakdowns,
      topProducts: tops,
    );
  }
}
