// lib/core/services/analytics_service.dart
//
// Capa de eventos (Data Layer) — define la taxonomía de eventos que la app
// emite y delega la entrega a uno o varios "sinks". Mantener el catálogo
// centralizado evita strings sueltos por toda la base de código y permite
// renombrar/eliminar eventos en un solo lugar.
//
// Diseño:
//   - `AnalyticsEvent` es un sealed-style enum con `name` y `params` libres.
//   - `AnalyticsSink` es la interfaz de salida. Hay dos implementaciones:
//       * `ConsoleAnalyticsSink` — imprime en debug (default).
//       * `FirebaseAnalyticsSink` — stub que documenta el wiring a
//          `firebase_analytics` (no se incluye el package para no requerir
//          configuración nativa extra en este sprint).
//   - Múltiples sinks pueden registrarse a la vez (fan-out).

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

/// Stub de Firebase Analytics. La integración real requiere agregar
/// `firebase_analytics` al pubspec y delegar al `FirebaseAnalytics.instance`.
/// Se mantiene aquí como punto de extensión documentado.
class FirebaseAnalyticsSink implements AnalyticsSink {
  @override
  Future<void> log(AnalyticsEvent event, Map<String, Object?> params) async {
    // Wiring esperado:
    //   await FirebaseAnalytics.instance.logEvent(
    //     name: event.name,
    //     parameters: params.cast<String, Object>(),
    //   );
    //
    // Mientras no se instale el package, este sink es un no-op silencioso.
    return;
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
