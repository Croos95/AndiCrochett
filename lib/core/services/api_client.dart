import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:andicrochett/core/config/env.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException(this.statusCode, this.message, {this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Función que provee el ID token de Firebase Auth. Es inyectable para tests.
typedef TokenProvider = Future<String> Function();

/// Cliente HTTP que consume el backend REST de AndiCrochett.
///
/// Adjunta automáticamente `Authorization: Bearer <FirebaseIdToken>` en
/// cada petición. Parsea respuestas JSON y lanza [ApiException] cuando
/// el servidor responde con 4xx/5xx.
class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? client,
    FirebaseAuth? auth,
    TokenProvider? tokenProvider,
  })  : _baseUrl = baseUrl ?? Env.baseUrl,
        _client = client ?? http.Client(),
        _tokenProvider = tokenProvider
            ?? _firebaseTokenProvider(auth ?? FirebaseAuth.instance);

  static final ApiClient instance = ApiClient();

  final String _baseUrl;
  final http.Client _client;
  final TokenProvider _tokenProvider;

  static TokenProvider _firebaseTokenProvider(FirebaseAuth auth) {
    return () async {
      final user = auth.currentUser;
      if (user == null) {
        throw StateError('No hay usuario autenticado');
      }
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw StateError('Firebase devolvió un ID token vacío');
      }
      return token;
    };
  }

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final token = await _tokenProvider();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse('$_baseUrl$cleanPath');
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        ...query.map((k, v) => MapEntry(k, v.toString())),
      },
    );
  }

  Future<dynamic> _decode(http.Response res) async {
    final isJson = (res.headers['content-type'] ?? '').contains('application/json');
    final body = res.body.isEmpty ? null : (isJson ? jsonDecode(res.body) : res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final msg = (body is Map && body['error'] != null)
        ? body['error'].toString()
        : (body is Map && body['errors'] is List)
              ? (body['errors'] as List).join(', ')
              : 'Error HTTP ${res.statusCode}';
    throw ApiException(res.statusCode, msg, body: body);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _client.get(_uri(path, query), headers: await _headers());
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await _client.post(
      _uri(path),
      headers: await _headers(jsonBody: true),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final res = await _client.put(
      _uri(path),
      headers: await _headers(jsonBody: true),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final res = await _client.patch(
      _uri(path),
      headers: await _headers(jsonBody: true),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<void> delete(String path) async {
    final res = await _client.delete(_uri(path), headers: await _headers());
    await _decode(res);
  }

  void dispose() => _client.close();
}
