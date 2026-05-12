// test/unit/services/analytics_service_test.dart
//
// Verifica la capa de eventos: que los nombres son estables, que el sink
// recibe los parámetros correctos y que el fan-out a múltiples sinks funciona.

import 'package:andicrochett/core/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsEvent', () {
    test('los nombres son snake_case y estables', () {
      // Si esto cambia, los reportes históricos pierden continuidad.
      expect(AnalyticsEvent.loginSuccess.name, 'login_success');
      expect(AnalyticsEvent.productCreated.name, 'product_created');
      expect(AnalyticsEvent.orderCreated.name, 'order_created');
      expect(AnalyticsEvent.screenViewed.name, 'screen_viewed');
    });
  });

  group('AnalyticsService', () {
    late InMemoryAnalyticsSink sink;

    setUp(() {
      sink = InMemoryAnalyticsSink();
      AnalyticsService.instance.configure([sink]);
    });

    test('log delega al sink con event y params', () async {
      await AnalyticsService.instance.log(
        AnalyticsEvent.productSearched,
        params: const {'query': 'estambre'},
      );

      expect(sink.calls, hasLength(1));
      expect(sink.calls.first.event, AnalyticsEvent.productSearched);
      expect(sink.calls.first.params['query'], 'estambre');
    });

    test('logProductCreated arma el payload tipado', () async {
      await AnalyticsService.instance.logProductCreated(productId: 9, name: 'X');

      final call = sink.calls.single;
      expect(call.event, AnalyticsEvent.productCreated);
      expect(call.params['product_id'], 9);
      expect(call.params['name'], 'X');
    });

    test('logOrderCreated incluye total e item_count', () async {
      await AnalyticsService.instance.logOrderCreated(
        orderId: 1,
        total: 199.99,
        itemCount: 3,
      );

      final call = sink.calls.single;
      expect(call.event, AnalyticsEvent.orderCreated);
      expect(call.params['order_id'], 1);
      expect(call.params['total'], 199.99);
      expect(call.params['item_count'], 3);
    });

    test('logLogin escoge success vs failed según el flag', () async {
      await AnalyticsService.instance.logLogin(method: 'email', success: true);
      await AnalyticsService.instance.logLogin(method: 'email', success: false);

      expect(sink.calls[0].event, AnalyticsEvent.loginSuccess);
      expect(sink.calls[1].event, AnalyticsEvent.loginFailed);
      expect(sink.calls[0].params['method'], 'email');
    });

    test('fan-out: configure([a, b]) entrega a ambos', () async {
      final a = InMemoryAnalyticsSink();
      final b = InMemoryAnalyticsSink();
      AnalyticsService.instance.configure([a, b]);

      await AnalyticsService.instance.log(AnalyticsEvent.logoutSuccess);

      expect(a.calls, hasLength(1));
      expect(b.calls, hasLength(1));
    });

    test('un sink que lanza excepción no detiene a los demás', () async {
      final failing = _ThrowingSink();
      final ok = InMemoryAnalyticsSink();
      AnalyticsService.instance.configure([failing, ok]);

      // No debe relanzar
      await AnalyticsService.instance.log(AnalyticsEvent.signUpSuccess);

      expect(ok.calls, hasLength(1));
    });
  });
}

class _ThrowingSink implements AnalyticsSink {
  @override
  Future<void> log(AnalyticsEvent event, Map<String, Object?> params) async {
    throw StateError('boom');
  }
}
