// lib/features/analytics/data/models/dashboard_metrics.dart
//
// DTOs inmutables que el AnalyticsRepository devuelve al dashboard. La idea
// es que la vista NO calcule agregaciones — solo renderice.

import 'package:flutter/foundation.dart';

@immutable
class StatusBreakdown {
  final String statusKey;
  final String label;
  final int count;

  const StatusBreakdown({
    required this.statusKey,
    required this.label,
    required this.count,
  });
}

@immutable
class TopProduct {
  final String name;
  final int unitsSold;
  final double revenue;

  const TopProduct({
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });
}

@immutable
class ProductNeedingRestock {
  final int id;
  final String name;
  final int currentStock;
  final String status; // 'low_stock' | 'out_of_stock'

  const ProductNeedingRestock({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.status,
  });
}

@immutable
class DashboardMetrics {
  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final int totalOrders;
  final int totalClients;
  final double revenueLast30Days;
  final List<StatusBreakdown> ordersByStatus;
  final List<TopProduct> topProducts;
  final List<ProductNeedingRestock> productsNeedingRestock;

  const DashboardMetrics({
    this.totalProducts = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.totalOrders = 0,
    this.totalClients = 0,
    this.revenueLast30Days = 0,
    this.ordersByStatus = const [],
    this.topProducts = const [],
    this.productsNeedingRestock = const [],
  });

  static const empty = DashboardMetrics();
}

// ─────────────────────────────────────────────────────────────────────────────
//  SecurityMetrics — alimenta la sección "Seguridad" del dashboard.
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class LoginAttemptsSummary {
  final int total;
  final int successful;
  final int failed;

  const LoginAttemptsSummary({
    this.total = 0,
    this.successful = 0,
    this.failed = 0,
  });

  double get successRate => total == 0 ? 0 : successful / total;
}

@immutable
class ApiCallsSummary {
  final int total;
  final int ok;
  final int unauthorized;
  final int serverErrors;
  final double avgDurationMs;

  const ApiCallsSummary({
    this.total = 0,
    this.ok = 0,
    this.unauthorized = 0,
    this.serverErrors = 0,
    this.avgDurationMs = 0,
  });
}

@immutable
class TopEndpoint {
  final String method;
  final String path;
  final int hits;

  const TopEndpoint({
    required this.method,
    required this.path,
    required this.hits,
  });
}

@immutable
class FailedLogin {
  final DateTime timestamp;
  final String email;
  final String errorMessage;
  final String ipAddress;

  const FailedLogin({
    required this.timestamp,
    required this.email,
    required this.errorMessage,
    required this.ipAddress,
  });
}

@immutable
class SecurityMetrics {
  final LoginAttemptsSummary loginAttempts;
  final ApiCallsSummary apiCalls24h;
  final List<TopEndpoint> topEndpoints;
  final List<FailedLogin> recentFailedLogins;

  const SecurityMetrics({
    this.loginAttempts = const LoginAttemptsSummary(),
    this.apiCalls24h = const ApiCallsSummary(),
    this.topEndpoints = const [],
    this.recentFailedLogins = const [],
  });

  static const empty = SecurityMetrics();
}
