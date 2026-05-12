// test/unit/services/exchange_rate_service_test.dart
//
// Verifica el cliente del servicio externo (frankfurter.app) sin pegarle
// a la red: usamos MockClient de package:http/testing.

import 'dart:convert';

import 'package:andicrochett/core/services/exchange_rate_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ExchangeRate.fromJson', () {
    test('parsea base, date y rates', () {
      final r = ExchangeRate.fromJson({
        'base': 'MXN',
        'date': '2026-05-01',
        'rates': {'USD': 0.058, 'EUR': 0.053},
      });
      expect(r.base, 'MXN');
      expect(r.date, DateTime(2026, 5, 1));
      expect(r.rates['USD'], 0.058);
      expect(r.rates['EUR'], 0.053);
    });

    test('convert multiplica por la tasa', () {
      final r = ExchangeRate(
        base: 'MXN',
        date: DateTime(2026, 5, 1),
        rates: const {'USD': 0.05, 'EUR': 0.045},
      );
      expect(r.convert(200, 'USD'), 10.0);
      expect(r.convert(200, 'EUR'), closeTo(9.0, 1e-9));
    });

    test('convert lanza si la moneda no está', () {
      final r = ExchangeRate(
        base: 'MXN',
        date: DateTime.now(),
        rates: const {'USD': 0.05},
      );
      expect(() => r.convert(100, 'JPY'), throwsA(isA<ExchangeRateException>()));
    });

    test('fromJson rechaza JSON sin "rates" como objeto', () {
      expect(
        () => ExchangeRate.fromJson({'base': 'MXN', 'rates': null}),
        throwsA(isA<ExchangeRateException>()),
      );
    });
  });

  group('ExchangeRateService.latest', () {
    test('arma la URL con from + to como CSV', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response(
          jsonEncode({
            'base': 'MXN',
            'date': '2026-05-01',
            'rates': {'USD': 0.058, 'EUR': 0.053},
          }),
          200,
        );
      });

      final service = ExchangeRateService(client: mock);
      final r = await service.latest(from: 'MXN', to: const ['USD', 'EUR']);

      expect(captured!.path, '/latest');
      expect(captured!.queryParameters['from'], 'MXN');
      expect(captured!.queryParameters['to'], 'USD,EUR');
      expect(r.base, 'MXN');
      expect(r.rates['USD'], 0.058);
    });

    test('lanza ExchangeRateException con statusCode en 5xx', () async {
      final mock = MockClient((_) async => http.Response('boom', 503));
      final service = ExchangeRateService(client: mock);

      await expectLater(
        service.latest(),
        throwsA(
          isA<ExchangeRateException>().having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('lanza si la respuesta no es JSON válido', () async {
      final mock = MockClient((_) async => http.Response('<not-json>', 200));
      final service = ExchangeRateService(client: mock);

      await expectLater(
        service.latest(),
        throwsA(isA<ExchangeRateException>()),
      );
    });
  });
}
