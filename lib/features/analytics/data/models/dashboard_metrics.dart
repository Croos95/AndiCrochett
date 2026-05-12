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
class DashboardMetrics {
  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final int totalOrders;
  final int totalClients;
  final double revenueLast30Days;
  final List<StatusBreakdown> ordersByStatus;
  final List<TopProduct> topProducts;

  const DashboardMetrics({
    this.totalProducts = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.totalOrders = 0,
    this.totalClients = 0,
    this.revenueLast30Days = 0,
    this.ordersByStatus = const [],
    this.topProducts = const [],
  });

  static const empty = DashboardMetrics();
}
