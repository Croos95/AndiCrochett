// lib/core/services/exchange_rate_service.dart
//
// Cliente del servicio público REST `api.frankfurter.app` (datos del Banco
// Central Europeo, sin API key). Demuestra:
//   - consumo de una API REST externa,
//   - parseo de JSON,
//   - integración de un servicio externo.
//
// Lo usamos en el dashboard de analítica para convertir los ingresos en MXN
// a USD/EUR en tiempo real, lo que da una segunda lectura útil al negocio.

import 'dart:convert';

import 'package:http/http.dart' as http;

class ExchangeRateException implements Exception {
  final int? statusCode;
  final String message;
  ExchangeRateException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'ExchangeRateException: $message'
      : 'ExchangeRateException($statusCode): $message';
}

/// Tipo de cambio de una moneda base a varias monedas destino, en una fecha.
class ExchangeRate {
  final String base;
  final DateTime date;
  final Map<String, double> rates;

  const ExchangeRate({
    required this.base,
    required this.date,
    required this.rates,
  });

  /// Convierte un monto en la moneda base a la moneda destino.
  /// Lanza si la moneda destino no está en el mapa.
  double convert(double amount, String to) {
    final rate = rates[to];
    if (rate == null) {
      throw ExchangeRateException('La tasa $base→$to no está disponible');
    }
    return amount * rate;
  }

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    final ratesJson = json['rates'];
    if (ratesJson is! Map) {
      throw ExchangeRateException(
        'Respuesta JSON inválida: "rates" no es objeto',
      );
    }
    final parsed = <String, double>{};
    ratesJson.forEach((k, v) {
      if (v is num) parsed[k.toString()] = v.toDouble();
    });
    return ExchangeRate(
      base: json['base']?.toString() ?? 'EUR',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      rates: parsed,
    );
  }
}

class ExchangeRateService {
  ExchangeRateService({
    http.Client? client,
    this.baseUrl = 'https://api.frankfurter.app',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// `GET /latest?from=<from>&to=<csv-de-monedas>`
  ///
  /// Por defecto consulta MXN → USD,EUR. Devuelve un `ExchangeRate` con los
  /// tipos vigentes según el Banco Central Europeo.
  Future<ExchangeRate> latest({
    String from = 'MXN',
    List<String> to = const ['USD', 'EUR'],
  }) async {
    final query = {'from': from, if (to.isNotEmpty) 'to': to.join(',')};
    final uri = Uri.parse('$baseUrl/latest').replace(queryParameters: query);

    final res = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw ExchangeRateException(
        'El servicio respondió con código no exitoso',
        statusCode: res.statusCode,
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ExchangeRateException('Respuesta no es JSON válido');
    }

    return ExchangeRate.fromJson(body);
  }

  void dispose() => _client.close();
}
