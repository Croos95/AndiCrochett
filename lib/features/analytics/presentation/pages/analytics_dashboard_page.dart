// lib/features/analytics/presentation/pages/analytics_dashboard_page.dart
//
// Página de analítica. Carga las métricas vía AnalyticsRepository y las
// muestra en una grid responsiva. Es la "vista de resultados" del Sprint 5.

import 'package:flutter/material.dart';
import 'package:andicrochett/core/services/analytics_service.dart';
import 'package:andicrochett/features/analytics/data/analytics_repository.dart';
import 'package:andicrochett/features/analytics/data/models/dashboard_metrics.dart';
import 'package:andicrochett/features/analytics/presentation/widgets/currency_conversion_card.dart';
import 'package:andicrochett/features/analytics/presentation/widgets/metric_card.dart';
import 'package:andicrochett/features/analytics/presentation/widgets/status_breakdown_bar.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key, AnalyticsRepository? repository})
      : _repository = repository;

  final AnalyticsRepository? _repository;

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  late final AnalyticsRepository _repo = widget._repository ?? AnalyticsRepository();
  late Future<DashboardMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.loadDashboard();
    AnalyticsService.instance.logScreen('analytics_dashboard');
  }

  void _reload() {
    setState(() {
      _future = _repo.loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analítica del negocio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<DashboardMetrics>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error al cargar métricas: ${snapshot.error}'),
              ),
            );
          }
          final m = snapshot.data ?? DashboardMetrics.empty;
          return _DashboardBody(metrics: m);
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 720
                ? 3
                : 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle('Resumen'),
              GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  MetricCard(
                    label: 'Productos',
                    value: metrics.totalProducts.toString(),
                    icon: Icons.inventory_2_outlined,
                  ),
                  MetricCard(
                    label: 'Bajo stock',
                    value: metrics.lowStockCount.toString(),
                    icon: Icons.warning_amber_outlined,
                    accentColor: const Color(0xFFE0A800),
                  ),
                  MetricCard(
                    label: 'Sin existencias',
                    value: metrics.outOfStockCount.toString(),
                    icon: Icons.error_outline,
                    accentColor: const Color(0xFFEF4444),
                  ),
                  MetricCard(
                    label: 'Pedidos totales',
                    value: metrics.totalOrders.toString(),
                    icon: Icons.shopping_bag_outlined,
                  ),
                  MetricCard(
                    label: 'Clientes',
                    value: metrics.totalClients.toString(),
                    icon: Icons.people_outline,
                  ),
                  MetricCard(
                    label: 'Ingresos 30 días',
                    value: '\$${metrics.revenueLast30Days.toStringAsFixed(2)}',
                    icon: Icons.payments_outlined,
                    accentColor: const Color(0xFF22C55E),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SectionTitle('Conversión de ingresos (API externa)'),
              CurrencyConversionCard(amountMxn: metrics.revenueLast30Days),
              const SizedBox(height: 28),
              _SectionTitle('Pedidos por estado'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StatusBreakdownBar(breakdown: metrics.ordersByStatus),
                ),
              ),
              const SizedBox(height: 28),
              _SectionTitle('Top productos vendidos'),
              if (metrics.topProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aún no hay ventas registradas.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      for (final p in metrics.topProducts)
                        ListTile(
                          leading: const Icon(Icons.local_offer_outlined),
                          title: Text(p.name),
                          subtitle: Text('${p.unitsSold} unidades · \$${p.revenue.toStringAsFixed(2)}'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
