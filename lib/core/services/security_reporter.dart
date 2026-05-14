// lib/core/services/security_reporter.dart
//
// Reporta intentos de login (success / fail) al backend para alimentar el
// dashboard de seguridad. El endpoint es público — no requiere token (los
// intentos fallidos NO tienen sesión todavía).
//
// Falla silenciosamente: si el backend está caído o la red no responde,
// loguear seguridad no debe bloquear el flujo de login del usuario.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:andicrochett/core/config/env.dart';

class SecurityReporter {
  SecurityReporter({String? baseUrl, http.Client? client})
    : _baseUrl = baseUrl ?? Env.baseUrl,
      _client = client ?? http.Client();

  static final SecurityReporter instance = SecurityReporter();

  final String _baseUrl;
  final http.Client _client;

  Future<void> reportLoginAttempt({
    required String email,
    required bool success,
    String? errorMessage,
  }) async {
    try {
      await _client
          .post(
            Uri.parse('$_baseUrl/security/login-attempt'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'success': success,
              if (errorMessage != null) 'errorMessage': errorMessage,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      // Nunca relanzamos: no queremos romper el login por un fallo de telemetría.
      debugPrint('[security] no se pudo reportar login attempt: $e');
    }
  }

  void dispose() => _client.close();
}
