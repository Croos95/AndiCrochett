// lib/core/services/secure_api_client.dart
//
// Cliente HTTP minimal para consumir las rutas `/secure/*` del backend.
// Inyecta automáticamente `Authorization: Bearer <token>` con el ID token
// vigente del usuario autenticado (Firebase Auth).
//
// Si no hay usuario logueado, las llamadas fallan rápido con StateError —
// la app debe verificar `isAuthenticated` ANTES de invocar al cliente.

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class SecureApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? body;

  SecureApiException(this.statusCode, this.message, {this.body});

  @override
  String toString() => 'SecureApiException($statusCode): $message';
}

class SecureApiClient {
  SecureApiClient({
    required this.baseUrl,
    http.Client? client,
    FirebaseAuth? auth,
  }) : _client = client ?? http.Client(),
       _auth = auth ?? FirebaseAuth.instance;

  /// Base de la API, p.ej. `https://us-central1-andicrochett-bcb21.cloudfunctions.net/api`
  /// o `http://localhost:5001/andicrochett-bcb21/us-central1/api` en emulador.
  final String baseUrl;

  final http.Client _client;
  final FirebaseAuth _auth;

  Future<String> _idToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'No hay usuario autenticado para hacer la llamada segura',
      );
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Firebase devolvió un ID token vacío');
    }
    return token;
  }

  /// GET sobre una ruta `/secure/<path>`. Devuelve el JSON parseado o lanza
  /// `SecureApiException` con el cuerpo del error.
  Future<Map<String, dynamic>> getSecure(String path) async {
    final token = await _idToken();
    final uri = Uri.parse('$baseUrl/secure$path');
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    throw SecureApiException(
      res.statusCode,
      body?['message']?.toString() ?? 'Error desconocido',
      body: body,
    );
  }

  void dispose() => _client.close();
}
