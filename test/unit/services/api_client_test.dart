// test/unit/services/api_client_test.dart
//
// Tests del ApiClient: armado de URL, inyección de Authorization, parseo de
// JSON, manejo de errores 4xx/5xx con cuerpo JSON, y query params.

import 'dart:convert';

import 'package:andicrochett/core/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _apiWith(
  Future<http.Response> Function(http.Request) handler, {
  String baseUrl = 'http://test.local/api',
  TokenProvider? tokenProvider,
}) {
  return ApiClient(
    baseUrl: baseUrl,
    client: MockClient(handler),
    tokenProvider: tokenProvider ?? () async => 'fake-token',
  );
}

void main() {
  group('ApiClient.get', () {
    test('agrega Authorization Bearer y Accept JSON', () async {
      late http.Request capturedRequest;
      final api = _apiWith((req) async {
        capturedRequest = req;
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      });

      await api.get('/designs');

      expect(capturedRequest.headers['Authorization'], 'Bearer fake-token');
      expect(capturedRequest.headers['Accept'], 'application/json');
      expect(capturedRequest.url.toString(), 'http://test.local/api/designs');
    });

    test('serializa query params correctamente', () async {
      late Uri capturedUri;
      final api = _apiWith((req) async {
        capturedUri = req.url;
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      });

      await api.get('/patterns', query: {'designId': 42});

      expect(capturedUri.queryParameters['designId'], '42');
    });

    test('parsea JSON de respuesta', () async {
      final api = _apiWith((_) async => http.Response(
            jsonEncode({'ok': true, 'count': 3}),
            200,
            headers: {'content-type': 'application/json'},
          ));

      final result = await api.get('/anything') as Map<String, dynamic>;
      expect(result['ok'], true);
      expect(result['count'], 3);
    });
  });

  group('ApiClient.post', () {
    test('envía body JSON y Content-Type', () async {
      late http.Request capturedRequest;
      final api = _apiWith((req) async {
        capturedRequest = req;
        return http.Response('{}', 201,
            headers: {'content-type': 'application/json'});
      });

      await api.post('/designs', body: {'nombre': 'X', 'descripcion': 'Y'});

      expect(capturedRequest.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(capturedRequest.body), {'nombre': 'X', 'descripcion': 'Y'});
    });
  });

  group('Manejo de errores', () {
    test('lanza ApiException con mensaje del backend en 4xx', () async {
      final api = _apiWith((_) async => http.Response(
            jsonEncode({'error': 'Falta el campo "nombre"'}),
            400,
            headers: {'content-type': 'application/json'},
          ));

      try {
        await api.get('/designs');
        fail('Debería haber lanzado ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 400);
        expect(e.message, 'Falta el campo "nombre"');
      }
    });

    test('lanza ApiException con lista de errores cuando viene "errors"', () async {
      final api = _apiWith((_) async => http.Response(
            jsonEncode({
              'errors': ['"tipo" inválido', '"design_id" no existe'],
            }),
            400,
            headers: {'content-type': 'application/json'},
          ));

      try {
        await api.post('/patterns', body: {});
        fail('Debería haber lanzado ApiException');
      } on ApiException catch (e) {
        expect(e.message, contains('"tipo" inválido'));
        expect(e.message, contains('"design_id" no existe'));
      }
    });

    test('propaga error de token cuando tokenProvider falla', () async {
      final api = _apiWith(
        (_) async => http.Response('[]', 200),
        tokenProvider: () async => throw StateError('No hay sesión'),
      );

      expect(api.get('/designs'), throwsA(isA<StateError>()));
    });
  });
}
