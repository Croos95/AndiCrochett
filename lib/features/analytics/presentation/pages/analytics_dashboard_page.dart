// lib/features/analytics/presentation/pages/analytics_dashboard_page.dart
//
// Página de analítica. Muestra dos secciones grandes:
//   1. NEGOCIO — métricas calculadas sobre la BD SQLite (productos, pedidos,
//      ingresos, top de ventas, productos por reabastecer).
//   2. SEGURIDAD — métricas de la tabla `audit_log` (intentos de login,
//      llamadas a la API, endpoints más golpeados, logins fallidos recientes).

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
  late final AnalyticsRepository _repo =
      widget._repository ?? AnalyticsRepository();
  late Future<DashboardMetrics> _businessFuture;
  late Future<SecurityMetrics> _securityFuture;

  @override
  void initState() {
    super.initState();
    _reloadAll();
    AnalyticsService.instance.logScreen('analytics_dashboard');
  }

  void _reloadAll() {
    _businessFuture = _repo.loadDashboard();
    _securityFuture = _repo.loadSecurity();
  }

  void _reload() {
    setState(_reloadAll);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analítica'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recargar',
              onPressed: _reload,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.insights_outlined), text: 'Negocio'),
              Tab(icon: Icon(Icons.shield_outlined), text: 'Seguridad'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BusinessTab(future: _businessFuture),
            _SecurityTab(future: _securityFuture),
          ],
        ),
      ),
    );
  }
}

// ─── Negocio ────────────────────────────────────────────────────────────────

class _BusinessTab extends StatelessWidget {
  const _BusinessTab({required this.future});

  final Future<DashboardMetrics> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardMetrics>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorBox(error: snapshot.error);
        }
        final m = snapshot.data ?? DashboardMetrics.empty;
        return _BusinessBody(metrics: m);
      },
    );
  }
}

class _BusinessBody extends StatelessWidget {
  const _BusinessBody({required this.metrics});

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
              const _SectionTitle('Resumen'),
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
              const _SectionTitle('Conversión de ingresos (API externa)'),
              CurrencyConversionCard(amountMxn: metrics.revenueLast30Days),
              const SizedBox(height: 28),
              const _SectionTitle('Pedidos por estado'),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StatusBreakdownBar(breakdown: metrics.ordersByStatus),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle('Top productos vendidos'),
              if (metrics.topProducts.isEmpty)
                _EmptyHint(
                  text: 'Aún no hay ventas registradas.',
                  theme: theme,
                )
              else
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (final p in metrics.topProducts)
                        ListTile(
                          leading: const Icon(Icons.local_offer_outlined),
                          title: Text(p.name),
                          subtitle: Text(
                            '${p.unitsSold} unidades · \$${p.revenue.toStringAsFixed(2)}',
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              const _SectionTitle('Productos por reabastecer'),
              if (metrics.productsNeedingRestock.isEmpty)
                _EmptyHint(
                  text: 'Tu inventario está al día. Sin reposiciones pendientes.',
                  theme: theme,
                )
              else
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (final p in metrics.productsNeedingRestock)
                        ListTile(
                          leading: Icon(
                            p.status == 'out_of_stock'
                                ? Icons.error_outline
                                : Icons.warning_amber_outlined,
                            color: p.status == 'out_of_stock'
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFE0A800),
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            p.status == 'out_of_stock'
                                ? 'Sin existencias'
                                : 'Quedan ${p.currentStock} unidades',
                          ),
                          trailing: Text(
                            '#${p.id}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
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

// ─── Seguridad ──────────────────────────────────────────────────────────────

class _SecurityTab extends StatelessWidget {
  const _SecurityTab({required this.future});

  final Future<SecurityMetrics> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SecurityMetrics>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorBox(error: snapshot.error);
        }
        final m = snapshot.data ?? SecurityMetrics.empty;
        return _SecurityBody(metrics: m);
      },
    );
  }
}

class _SecurityBody extends StatelessWidget {
  const _SecurityBody({required this.metrics});

  final SecurityMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String formatTimestamp(DateTime dt) {
      String p(int n) => n.toString().padLeft(2, '0');
      final l = dt.toLocal();
      return '${p(l.day)}/${p(l.month)}/${l.year} ${p(l.hour)}:${p(l.minute)}';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 720
            ? 3
            : 2;

        final la = metrics.loginAttempts;
        final ac = metrics.apiCalls24h;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionTitle('Intentos de inicio de sesión (7 días)'),
              GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  MetricCard(
                    label: 'Total intentos',
                    value: la.total.toString(),
                    icon: Icons.login_outlined,
                  ),
                  MetricCard(
                    label: 'Exitosos',
                    value: la.successful.toString(),
                    icon: Icons.check_circle_outline,
                    accentColor: const Color(0xFF22C55E),
                  ),
                  MetricCard(
                    label: 'Fallidos',
                    value: la.failed.toString(),
                    icon: Icons.cancel_outlined,
                    accentColor: const Color(0xFFEF4444),
                  ),
                  MetricCard(
                    label: 'Tasa de éxito',
                    value: '${(la.successRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.percent,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionTitle('Llamadas a la API (24h)'),
              GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  MetricCard(
                    label: 'Total',
                    value: ac.total.toString(),
                    icon: Icons.cloud_outlined,
                  ),
                  MetricCard(
                    label: 'Exitosas',
                    value: ac.ok.toString(),
                    icon: Icons.check,
                    accentColor: const Color(0xFF22C55E),
                  ),
                  MetricCard(
                    label: 'No autorizadas',
                    value: ac.unauthorized.toString(),
                    icon: Icons.lock_outline,
                    accentColor: const Color(0xFFE0A800),
                  ),
                  MetricCard(
                    label: 'Errores 5xx',
                    value: ac.serverErrors.toString(),
                    icon: Icons.cloud_off_outlined,
                    accentColor: const Color(0xFFEF4444),
                  ),
                  MetricCard(
                    label: 'Latencia prom.',
                    value: '${ac.avgDurationMs.toStringAsFixed(0)} ms',
                    icon: Icons.speed,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionTitle('Endpoints más usados (24h)'),
              if (metrics.topEndpoints.isEmpty)
                _EmptyHint(text: 'Aún sin tráfico registrado.', theme: theme)
              else
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (final e in metrics.topEndpoints)
                        ListTile(
                          leading: const Icon(Icons.api_outlined),
                          title: Text(
                            '${e.method} ${e.path}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          trailing: Text(
                            '${e.hits} hits',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              const _SectionTitle('Logins fallidos recientes'),
              if (metrics.recentFailedLogins.isEmpty)
                _EmptyHint(
                  text: 'Sin intentos fallidos en los últimos 7 días.',
                  theme: theme,
                )
              else
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (final f in metrics.recentFailedLogins)
                        ListTile(
                          leading: const Icon(
                            Icons.warning_amber_outlined,
                            color: Color(0xFFE0A800),
                          ),
                          title: Text(f.email.isEmpty ? '(sin email)' : f.email),
                          subtitle: Text(
                            '${formatTimestamp(f.timestamp)}'
                            '${f.errorMessage.isEmpty ? '' : ' · ${f.errorMessage}'}',
                          ),
                          trailing: f.ipAddress.isEmpty
                              ? null
                              : Text(
                                  f.ipAddress,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
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

// ─── Compartidos ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error al cargar métricas: $error'),
      ),
    );
  }
}
