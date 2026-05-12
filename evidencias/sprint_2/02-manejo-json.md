# Sprint 2 · Manejo de JSON

## Tres lugares donde se manipula JSON en el proyecto

### 1. JSON de API REST externa
`ExchangeRate.fromJson` en [`exchange_rate_service.dart`](../../lib/core/services/exchange_rate_service.dart):

```dart
factory ExchangeRate.fromJson(Map<String, dynamic> json) {
  final ratesJson = json['rates'];
  if (ratesJson is! Map) {
    throw ExchangeRateException('Respuesta JSON inválida: "rates" no es objeto');
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
```

- Valida el tipo de cada campo (`is! Map`, `v is num`).
- Tolera campos faltantes con defaults (`?? 'EUR'`).
- Convierte `String` ISO-8601 → `DateTime` con `tryParse` (devuelve null si falla, en vez de tronar).

### 2. JSON dentro de SQLite (settings)
`UserSettings` se guarda como **JSON string en una columna** de la tabla `usuarios`:

```dart
// UserModel.toMap
'settings': jsonEncode(settings.toMap()),

// UserModel.fromMap
UserSettings s = const UserSettings();
if (map['settings'] != null) {
  try {
    s = UserSettings.fromMap(jsonDecode(map['settings']));
  } catch (_) {}
}
```

Decisión: en vez de añadir 3 columnas (`theme`, `language`, `notifications`), las metimos en una sola columna `settings TEXT`. Trade-off: no se puede `WHERE settings.theme = 'dark'`, pero el negocio nunca filtra por preferencias del usuario en SQL.

### 3. JSON dentro de SQLite (items de pedido legacy)
`pedidos.items_json` (columna `TEXT DEFAULT '[]'`) guardaba snapshots de items antes de que tuviéramos `items_pedido` como tabla normalizada. Sigue presente para compatibilidad con datos viejos (ver migración v4 en `database_helper.dart`).

## Estrategia general de parseo
1. **Función factory**: cada modelo expone `fromMap`/`fromJson` que es la única forma de construirlo desde data externa. No se construyen modelos a mano a partir de Maps.
2. **Defaults defensivos**: `(map['cantidad'] as num?)?.toInt() ?? 0` — si llega null o tipo raro, no truena.
3. **Re-encode estricto**: `toMap` usa claves explícitas con tipos conocidos. No hay `Map.from(...)` de cosas dinámicas.

## Tests de parseo
[`test/unit/services/exchange_rate_service_test.dart`](../../test/unit/services/exchange_rate_service_test.dart):

| Test | Verifica |
|---|---|
| parsea base, date y rates | Happy path |
| convert multiplica por la tasa | Lógica de conversión |
| convert lanza si la moneda no está | Caso de error explícito |
| fromJson rechaza JSON sin "rates" como objeto | Defensiva contra malformados |
| arma la URL con from + to como CSV | El request es correcto |
| lanza ExchangeRateException con statusCode en 5xx | Errores HTTP |
| lanza si la respuesta no es JSON válido | Errores de parseo |

**7 tests pasan**, todos sin tocar la red.

Para SQLite/JSON tests adicionales ver [`test/unit/models/user_model_test.dart`](../../test/unit/models/user_model_test.dart) (Sprint 4) — verifica el round-trip de UserSettings.

## Por qué no codegen (`json_serializable`)
- Modelos pequeños (< 10 campos), no justifica el overhead de `build_runner`.
- Los `fromMap` actuales son explícitos sobre defaults y validación — codegen los hace genéricos y pierde ese control.
- Si en el futuro hay > 20 modelos, vale la pena migrar.
