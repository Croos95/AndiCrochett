// test/e2e/analytics_dashboard_e2e_test.dart
//
// Prueba E2E del AnalyticsDashboardPage. Cubre todo el camino de extremo a
// extremo desde la capa HTTP hasta el render:
//   - Loading inicial (spinner)
//   - Parsing del JSON de /api/analytics/dashboard → tarjetas de negocio
//   - Cambio a la pestaña "Seguridad" + render de las métricas
//   - Reload via el botón de la AppBar
//   - Manejo de error si el backend responde 5xx
//
// La capa HTTP se reemplaza con `MockClient` para que el test no toque red
// real ni Firebase. El `ApiClient` se construye con un `tokenProvider` que
// devuelve un token sintético — sin Firebase Auth inicializado.
//
// Vive bajo `test/e2e/` (no `integration_test/`) para poder correr en CI sin
// device físico. Se ejecuta con:
//
//   flutter test test/e2e/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:andicrochett/core/services/api_client.dart';
import 'package:andicrochett/features/analytics/data/analytics_repository.dart';
import 'package:andicrochett/features/analytics/presentation/pages/analytics_dashboard_page.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────

const _dashboardJson = {
  'totalProducts': 14,
  'lowStockCount': 2,
  'outOfStockCount': 1,
  'totalOrders': 6,
  'totalClients': 4,
  'revenueLast30Days': 1850.5,
  'ordersByStatus': [
    {'statusKey': 'pending', 'count': 3},
    {'statusKey': 'completed', 'count': 2},
    {'statusKey': 'cancelled', 'count': 1},
  ],
  'topProducts': [
    {'name': 'Gorro tejido', 'unitsSold': 8, 'revenue': 1200.0},
    {'name': 'Bufanda larga', 'unitsSold': 3, 'revenue': 450.0},
  ],
  'productsNeedingRestock': [
    {'id': 7, 'name': 'Estambre azul', 'currentStock': 0, 'status': 'out_of_stock'},
    {'id': 12, 'name': 'Aguja 3mm', 'currentStock': 3, 'status': 'low_stock'},
  ],
};

const _securityJson = {
  'loginAttempts': {'total': 10, 'successful': 8, 'failed': 2},
  'apiCalls24h': {
    'total': 124,
    'ok': 118,
    'unauthorized': 4,
    'serverErrors': 2,
    'avgDurationMs': 12.5,
  },
  'topEndpoints': [
    {'method': 'GET', 'path': '/api/designs', 'hits': 40},
    {'method': 'POST', 'path': '/api/orders', 'hits': 8},
  ],
  'recentFailedLogins': [
    {
      'timestamp': '2026-05-13T14:22:00.000Z',
      'email': 'atacante@example.com',
      'errorMessage': 'wrong-password',
      'ipAddress': '203.0.113.7',
    },
  ],
};

/// Construye un AnalyticsRepository que responde con las fixtures de arriba.
/// Si `failDashboard` es true, devuelve 500 al pegarle a /dashboard.
AnalyticsRepository _repoWith({bool failDashboard = false}) {
  final client = MockClient((req) async {
    if (req.url.path.endsWith('/dashboard')) {
      if (failDashboard) {
        return http.Response(
          jsonEncode({'error': 'BD caída'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode(_dashboardJson),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (req.url.path.endsWith('/security')) {
      return http.Response(
        jsonEncode(_securityJson),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('not found', 404);
  });

  return AnalyticsRepository(
    api: ApiClient(
      baseUrl: 'http://test.local/api',
      client: client,
      tokenProvider: () async => 'fake-token',
    ),
  );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

// Surface de tamaño desktop para que la grilla de MetricCards no overflowee
// con el viewport por defecto de los widget tests (800x600).
const _desktopSize = Size(1400, 1000);

void main() {
  testWidgets('flujo completo: loading → datos de negocio → seguridad → reload',
      (tester) async {
    await tester.binding.setSurfaceSize(_desktopSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: AnalyticsDashboardPage(repository: _repoWith()),
    ));

    // ── 1. Estado de loading ────────────────────────────────────────────────
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // El TabBar ya está montado desde el primer frame.
    expect(find.text('Negocio'), findsOneWidget);
    expect(find.text('Seguridad'), findsOneWidget);

    await tester.pumpAndSettle();

    // ── 2. Pestaña Negocio renderizada con datos del fixture ────────────────
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('14'), findsOneWidget); // totalProducts
    expect(find.text('Pedidos totales'), findsOneWidget);
    expect(find.text('6'), findsOneWidget); // totalOrders
    expect(find.text('Ingresos 30 días'), findsOneWidget);
    expect(find.textContaining('1850.50'), findsOneWidget);

    // Top productos
    expect(find.text('Gorro tejido'), findsOneWidget);
    expect(find.textContaining('8 unidades'), findsOneWidget);

    // Productos por reabastecer (aparecen "Bajo stock" y "Sin existencias"
    // dos veces: una en la tarjeta de métrica y otra como subtítulo del
    // ListTile del producto correspondiente — por eso findsWidgets).
    expect(find.text('Productos por reabastecer'), findsOneWidget);
    expect(find.text('Estambre azul'), findsOneWidget);
    expect(find.text('Sin existencias'), findsWidgets);
    expect(find.text('Aguja 3mm'), findsOneWidget);
    expect(find.textContaining('Quedan 3 unidades'), findsOneWidget);

    // ── 3. Cambio a la pestaña Seguridad ────────────────────────────────────
    await tester.tap(find.text('Seguridad'));
    await tester.pumpAndSettle();

    expect(find.text('Intentos de inicio de sesión (7 días)'), findsOneWidget);
    expect(find.text('Total intentos'), findsOneWidget);
    expect(find.text('10'), findsOneWidget); // total
    expect(find.text('Exitosos'), findsOneWidget);
    expect(find.text('Fallidos'), findsOneWidget);
    expect(find.text('Tasa de éxito'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget); // 8/10

    // API calls 24h
    expect(find.text('Llamadas a la API (24h)'), findsOneWidget);
    expect(find.text('124'), findsOneWidget); // ac.total
    expect(find.text('No autorizadas'), findsOneWidget);
    expect(find.text('Errores 5xx'), findsOneWidget);
    expect(find.text('13 ms'), findsOneWidget); // avgDurationMs redondeado

    // Endpoints top
    expect(find.textContaining('GET /api/designs'), findsOneWidget);
    expect(find.text('40 hits'), findsOneWidget);

    // Logins fallidos recientes
    expect(find.text('Logins fallidos recientes'), findsOneWidget);
    expect(find.text('atacante@example.com'), findsOneWidget);
    expect(find.textContaining('wrong-password'), findsOneWidget);
    expect(find.text('203.0.113.7'), findsOneWidget);

    // ── 4. Reload via el botón de la AppBar ─────────────────────────────────
    await tester.tap(find.byTooltip('Recargar'));
    await tester.pump(); // dispara setState
    // Spinner reaparece mientras el Future se rehace.
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pumpAndSettle();

    // Tras el reload seguimos viendo los datos (mismo fixture).
    expect(find.text('atacante@example.com'), findsOneWidget);
  });

  testWidgets('si el backend devuelve 500 muestra el mensaje de error',
      (tester) async {
    await tester.binding.setSurfaceSize(_desktopSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: AnalyticsDashboardPage(repository: _repoWith(failDashboard: true)),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Error al cargar métricas'), findsOneWidget);
    expect(find.textContaining('BD caída'), findsOneWidget);
  });
}
