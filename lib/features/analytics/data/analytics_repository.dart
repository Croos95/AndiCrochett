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

    final restock = (data['productsNeedingRestock'] as List? ?? const [])
        .map((raw) {
          final m = raw as Map<String, dynamic>;
          return ProductNeedingRestock(
            id: (m['id'] as num?)?.toInt() ?? 0,
            name: m['name'] as String? ?? '',
            currentStock: (m['currentStock'] as num?)?.toInt() ?? 0,
            status: m['status'] as String? ?? 'low_stock',
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
      productsNeedingRestock: restock,
    );
  }

  /// Métricas de seguridad: intentos de login, llamadas a la API, endpoints
  /// más hitteados y logins fallidos recientes. Alimenta la sección de
  /// seguridad del dashboard.
  Future<SecurityMetrics> loadSecurity() async {
    final data = await _api.get('/analytics/security') as Map<String, dynamic>;

    Map<String, dynamic> asMap(dynamic v) =>
        (v as Map<String, dynamic>?) ?? const {};

    final la = asMap(data['loginAttempts']);
    final ac = asMap(data['apiCalls24h']);

    final tops = (data['topEndpoints'] as List? ?? const [])
        .map((raw) {
          final m = raw as Map<String, dynamic>;
          return TopEndpoint(
            method: m['method'] as String? ?? 'GET',
            path: m['path'] as String? ?? '',
            hits: (m['hits'] as num?)?.toInt() ?? 0,
          );
        })
        .toList();

    final fails = (data['recentFailedLogins'] as List? ?? const [])
        .map((raw) {
          final m = raw as Map<String, dynamic>;
          return FailedLogin(
            timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '')
                ?? DateTime.now(),
            email: m['email'] as String? ?? '',
            errorMessage: m['errorMessage'] as String? ?? '',
            ipAddress: m['ipAddress'] as String? ?? '',
          );
        })
        .toList();

    return SecurityMetrics(
      loginAttempts: LoginAttemptsSummary(
        total: (la['total'] as num?)?.toInt() ?? 0,
        successful: (la['successful'] as num?)?.toInt() ?? 0,
        failed: (la['failed'] as num?)?.toInt() ?? 0,
      ),
      apiCalls24h: ApiCallsSummary(
        total: (ac['total'] as num?)?.toInt() ?? 0,
        ok: (ac['ok'] as num?)?.toInt() ?? 0,
        unauthorized: (ac['unauthorized'] as num?)?.toInt() ?? 0,
        serverErrors: (ac['serverErrors'] as num?)?.toInt() ?? 0,
        avgDurationMs: (ac['avgDurationMs'] as num?)?.toDouble() ?? 0,
      ),
      topEndpoints: tops,
      recentFailedLogins: fails,
    );
  }
}
