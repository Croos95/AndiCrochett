// lib/features/analytics/presentation/widgets/currency_conversion_card.dart
//
// Llama al servicio externo `ExchangeRateService` y muestra los ingresos
// MXN convertidos a USD/EUR. Demuestra consumo de API REST + manejo de
// JSON en una UI real.

import 'package:flutter/material.dart';

import 'package:andicrochett/core/services/exchange_rate_service.dart';

class CurrencyConversionCard extends StatefulWidget {
  const CurrencyConversionCard({
    super.key,
    required this.amountMxn,
    ExchangeRateService? service,
  }) : _service = service;

  /// Monto en pesos mexicanos que se convertirá.
  final double amountMxn;

  final ExchangeRateService? _service;

  @override
  State<CurrencyConversionCard> createState() => _CurrencyConversionCardState();
}

class _CurrencyConversionCardState extends State<CurrencyConversionCard> {
  late final ExchangeRateService _service =
      widget._service ?? ExchangeRateService();
  late Future<ExchangeRate> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.latest(from: 'MXN', to: const ['USD', 'EUR']);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<ExchangeRate>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Consultando tipo de cambio...'),
                ],
              );
            }
            if (snapshot.hasError) {
              return Text(
                'No se pudo consultar el tipo de cambio: ${snapshot.error}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              );
            }

            final r = snapshot.data!;
            final usd = r.convert(widget.amountMxn, 'USD');
            final eur = r.convert(widget.amountMxn, 'EUR');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.currency_exchange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Equivalente en otras monedas',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tasa publicada el ${r.date.toIso8601String().split("T").first} (fuente: frankfurter.app)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _Row(label: 'USD', value: '\$${usd.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                _Row(label: 'EUR', value: '€${eur.toStringAsFixed(2)}'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
