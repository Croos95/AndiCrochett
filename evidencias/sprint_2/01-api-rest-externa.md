# Sprint 2 · Consumo de API REST

## Qué API y por qué
**`api.frankfurter.app`** — servicio público del Banco Central Europeo que devuelve tipos de cambio actualizados diariamente. Razones:

- **Sin API key**: no requiere registro ni manejo de secretos.
- **Sin rate limits agresivos**: suficiente para una app de microempresa.
- **JSON limpio**: estructura simple, ideal para demostrar parseo.
- **Relevante al negocio**: una crochet-business que quiere vender al extranjero necesita ver sus ingresos en USD/EUR.

### Endpoint usado
```
GET https://api.frankfurter.app/latest?from=MXN&to=USD,EUR
```

### Respuesta
```json
{
  "amount": 1.0,
  "base": "MXN",
  "date": "2026-05-01",
  "rates": {
    "USD": 0.058,
    "EUR": 0.053
  }
}
```

## Cliente Dart
[`lib/core/services/exchange_rate_service.dart`](../../lib/core/services/exchange_rate_service.dart):

```dart
class ExchangeRateService {
  ExchangeRateService({http.Client? client, this.baseUrl = 'https://api.frankfurter.app'})
      : _client = client ?? http.Client();

  Future<ExchangeRate> latest({
    String from = 'MXN',
    List<String> to = const ['USD', 'EUR'],
  }) async {
    final uri = Uri.parse('$baseUrl/latest').replace(queryParameters: {
      'from': from,
      if (to.isNotEmpty) 'to': to.join(','),
    });
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});

    if (res.statusCode != 200) {
      throw ExchangeRateException('...', statusCode: res.statusCode);
    }
    return ExchangeRate.fromJson(jsonDecode(res.body));
  }
}
```

Puntos clave:

- **`http.Client` inyectable**: facilita testing con `MockClient`.
- **`baseUrl` configurable**: permite cambiar a un mirror o staging.
- **Query params estructurados**: `Uri.replace` + map → no concatenación manual de strings (evita escapado defectuoso).
- **Exception tipada**: el caller distingue entre fallas de red (`statusCode == null`) y errores HTTP (`statusCode` no nulo).

## Errores manejados
| Causa | Cómo se manifiesta | Cómo se maneja |
|---|---|---|
| Sin red | `http.get` lanza `SocketException` | El caller la captura como `Exception` |
| HTTP 5xx | `statusCode != 200` | `ExchangeRateException(statusCode: 503)` |
| HTML en vez de JSON | `jsonDecode` lanza | `ExchangeRateException('Respuesta no es JSON válido')` |
| `rates` faltante | `r['rates']` no es Map | `ExchangeRateException('Respuesta JSON inválida...')` |
| Moneda no disponible | `convert(amount, 'JPY')` | `ExchangeRateException('La tasa MXN→JPY no está disponible')` |

Todos están cubiertos por tests — ver [02-manejo-json.md](02-manejo-json.md).

## Render en el dashboard
[`CurrencyConversionCard`](../../lib/features/analytics/presentation/widgets/currency_conversion_card.dart) hace el `FutureBuilder` y muestra:

```
[💱] Equivalente en otras monedas
     Tasa publicada el 2026-05-01 (fuente: frankfurter.app)

     USD   $116.00
     EUR   €106.00
```

Se monta automáticamente cuando el usuario abre `/analytics` — sin botón extra. Si la red falla, muestra un mensaje de error y el resto del dashboard sigue funcionando (degradación graceful).

## Trazabilidad del request
La llamada se puede ver en:
- **Chrome DevTools → Network** (filtrar por `frankfurter`).
- **Consola del navegador**: no se loggea automáticamente, pero el `debugPrint` del Analytics service registra el `screen_viewed` cuando se abre el dashboard.
