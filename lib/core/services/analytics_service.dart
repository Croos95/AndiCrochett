// lib/core/services/analytics_service.dart
//
// Capa de eventos (Data Layer) — define la taxonomía de eventos que la app
// emite y delega la entrega a uno o varios "sinks". Mantener el catálogo
// centralizado evita strings sueltos por toda la base de código y permite
// renombrar/eliminar eventos en un solo lugar.
//
// Diseño:
//   - `AnalyticsEvent` es un sealed-style enum con `name` y `params` libres.
//   - `AnalyticsSink` es la interfaz de salida. Hay tres implementaciones:
//       * `ConsoleAnalyticsSink` — imprime en debug.
//       * `FirebaseAnalyticsSink` — envía cada evento a Firebase Analytics
//          vía `firebase_analytics`.
//       * `InMemoryAnalyticsSink` — captura las llamadas en una lista para tests.
//   - Múltiples sinks pueden registrarse a la vez (fan-out).

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Catálogo cerrado de nombres de evento. Cambiar un nombre aquí impacta
/// reportes históricos — evitar renombrar a la ligera.
enum AnalyticsEvent {
  // ── Autenticación ─────────────────────────────────────────────────────────
  loginSuccess('login_success'),
  loginFailed('login_failed'),
  signUpSuccess('sign_up_success'),
  logoutSuccess('logout_success'),

  // ── Inventario ────────────────────────────────────────────────────────────
  productCreated('product_created'),
  productUpdated('product_updated'),
  productDeleted('product_deleted'),
  productSearched('product_searched'),

  // ── Pedidos / Agenda ──────────────────────────────────────────────────────
  orderCreated('order_created'),
  orderStatusChanged('order_status_changed'),
  orderCancelled('order_cancelled'),

  // ── Patrones / Diseños ────────────────────────────────────────────────────
  patternCreated('pattern_created'),
  designCreated('design_created'),

  // ── Navegación ────────────────────────────────────────────────────────────
  screenViewed('screen_viewed');

  const AnalyticsEvent(this.name);

  /// Nombre canónico que se envía a los sinks. snake_case por convención de
  /// Firebase Analytics y la mayoría de las plataformas BI.
  final String name;
}

/// Sumidero de eventos. Cualquier integración (Firebase, Mixpanel, archivo)
/// implementa esta interfaz.
abstract class AnalyticsSink {
  Future<void> log(AnalyticsEvent event, Map<String, Object?> params);
}

/// Sink de desarrollo: imprime cada evento en consola en `kDebugMode`.
/// En release no imprime nada para no contaminar logs.
class ConsoleAnalyticsSink implements AnalyticsSink {
  @override
  Future<void> log(AnalyticsEvent event, Map<String, Object?> params) async {
    if (!kDebugMode) return;
    final payload = params.isEmpty ? '' : ' $params';
    debugPrint('[analytics] ${event.name}$payload');
  }
}

/// Envía cada evento a Firebase Analytics.
///
/// El SDK rechaza valores `null` y nombres/params que no cumplan sus reglas
/// (snake_case, ≤40 chars, valores `num`/`String`/`bool`). Aquí saneamos para
/// que llamadas con `null` o tipos exóticos no rompan el envío.
class FirebaseAnalyticsSink implements AnalyticsSink {
  FirebaseAnalyticsSink({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  FirebaseAnalytics get analytics => _analytics;

  @override
  Future<void> log(AnalyticsEvent event, Map<String, Object?> params) async {
    final sanitized = <String, Object>{};
    params.forEach((key, value) {
      if (value == null) return;
      if (value is num || value is String || value is bool) {
        sanitized[key] = value;
      } else {
        sanitized[key] = value.toString();
      }
    });

    await _analytics.logEvent(
      name: event.name,
      parameters: sanitized.isEmpty ? null : sanitized,
    );
  }

  /// Atajo idiomático del SDK para registrar pantallas.
  Future<void> logScreenView(String name) async {
    await _analytics.logScreenView(screenName: name);
  }

  /// Asocia el UID al usuario actual — útil para reportes de retención.
  Future<void> setUserId(String? uid) async {
    await _analytics.setUserId(id: uid);
  }
}

/// Sink en memoria para pruebas — guarda lo que se logueó.
@visibleForTesting
class InMemoryAnalyticsSink implements AnalyticsSink {
  final List<({AnalyticsEvent event, Map<String, Object?> params})> calls = [];

  @override
  Future<void> log(AnalyticsEvent event, Map<String, Object?> params) async {
    calls.add((event: event, params: Map<String, Object?>.from(params)));
  }

  void reset() => calls.clear();
}

/// Punto de entrada único. Mantén `instance` como singleton; configura los
/// sinks una sola vez al inicio (en `main.dart` después de Firebase.init).
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final List<AnalyticsSink> _sinks = [ConsoleAnalyticsSink()];

  /// Reemplaza los sinks por completo. Útil en tests y al iniciar la app.
  void configure(List<AnalyticsSink> sinks) {
    _sinks
      ..clear()
      ..addAll(sinks);
  }

  /// Agrega un sink adicional sin tocar los existentes.
  void addSink(AnalyticsSink sink) => _sinks.add(sink);

  /// Emite un evento a todos los sinks registrados. Nunca relanza errores
  /// de los sinks — analítica no debe tumbar features de producto.
  Future<void> log(
    AnalyticsEvent event, {
    Map<String, Object?> params = const {},
  }) async {
    for (final sink in _sinks) {
      try {
        await sink.log(event, params);
      } catch (e, st) {
        // Solo loggeamos en debug; nunca propagamos.
        debugPrint('[analytics] sink failed: $e\n$st');
      }
    }
  }

  /// Helpers tipados para los eventos más usados — reducen el riesgo de
  /// olvidar parámetros clave en cada call site.

  Future<void> logScreen(String name) =>
      log(AnalyticsEvent.screenViewed, params: {'screen_name': name});

  Future<void> logProductCreated({
    required int productId,
    required String name,
  }) => log(
    AnalyticsEvent.productCreated,
    params: {'product_id': productId, 'name': name},
  );

  Future<void> logOrderCreated({
    required int orderId,
    required double total,
    required int itemCount,
  }) => log(
    AnalyticsEvent.orderCreated,
    params: {'order_id': orderId, 'total': total, 'item_count': itemCount},
  );

  Future<void> logLogin({required String method, required bool success}) => log(
    success ? AnalyticsEvent.loginSuccess : AnalyticsEvent.loginFailed,
    params: {'method': method},
  );
}
