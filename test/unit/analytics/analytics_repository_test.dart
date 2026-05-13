// test/unit/analytics/analytics_repository_test.dart
//
// Verifica que AnalyticsRepository parsea correctamente la respuesta del
// endpoint /analytics/dashboard. Usa MockClient para evitar red real;
// inyecta un TokenProvider falso para evitar Firebase.

import 'dart:convert';

import 'package:andicrochett/core/services/api_client.dart';
import 'package:andicrochett/features/analytics/data/analytics_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _apiWith(Map<String, dynamic> response, {int statusCode = 200}) {
  final client = MockClient((req) async {
    expect(req.headers['Authorization'], 'Bearer test-token');
    expect(req.url.path, contains('/analytics/dashboard'));
    return http.Response(
      jsonEncode(response),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  });
  return ApiClient(
    baseUrl: 'http://test.local/api',
    client: client,
    tokenProvider: () async => 'test-token',
  );
}

void main() {
  group('AnalyticsRepository.loadDashboard', () {
    test('parsea todos los campos del DTO', () async {
      final repo = AnalyticsRepository(
        api: _apiWith({
          'totalProducts': 12,
          'lowStockCount': 3,
          'outOfStockCount': 1,
          'totalOrders': 7,
          'totalClients': 5,
          'revenueLast30Days': 2540.50,
          'ordersByStatus': [
            {'statusKey': 'pending', 'count': 3},
            {'statusKey': 'completed', 'count': 2},
          ],
          'topProducts': [
            {'name': 'Gorro', 'unitsSold': 10, 'revenue': 1000.0},
            {'name': 'Bufanda', 'unitsSold': 3, 'revenue': 600.0},
          ],
        }),
      );

      final m = await repo.loadDashboard();

      expect(m.totalProducts, 12);
      expect(m.lowStockCount, 3);
      expect(m.outOfStockCount, 1);
      expect(m.totalOrders, 7);
      expect(m.totalClients, 5);
      expect(m.revenueLast30Days, 2540.50);

      expect(m.ordersByStatus, hasLength(2));
      expect(m.ordersByStatus.first.statusKey, 'pending');
      expect(m.ordersByStatus.first.count, 3);
      expect(m.ordersByStatus.first.label, 'Pendiente');

      expect(m.topProducts, hasLength(2));
      expect(m.topProducts.first.name, 'Gorro');
      expect(m.topProducts.first.unitsSold, 10);
      expect(m.topProducts.first.revenue, 1000.0);
    });

    test('soporta campos faltantes con defaults', () async {
      final repo = AnalyticsRepository(api: _apiWith({}));
      final m = await repo.loadDashboard();

      expect(m.totalProducts, 0);
      expect(m.revenueLast30Days, 0);
      expect(m.ordersByStatus, isEmpty);
      expect(m.topProducts, isEmpty);
    });

    test('propaga ApiException cuando el backend devuelve error', () async {
      final repo = AnalyticsRepository(
        api: _apiWith({'error': 'Token inválido'}, statusCode: 401),
      );

      expect(repo.loadDashboard(), throwsA(isA<ApiException>()));
    });
  });
}
