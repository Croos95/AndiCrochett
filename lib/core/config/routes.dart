import 'package:flutter/material.dart';
import 'package:andicrochett/features/auth/presentation/pages/login_page.dart';
import 'package:andicrochett/features/dashboard/presentation/pages/dashboard_page.dart';

// =============================================================================
//  AppRoutes
//  Define todas las rutas nombradas de la aplicación y helpers de navegación.
//
//  La navegación entre pantallas principales (inventory, patterns, designs)
//  se realiza mediante el sidebar del DashboardPage, no mediante rutas nombradas.
//  Las rutas nombradas solo se usan para las transiciones de autenticación.
//
//  TODO: Migrar a go_router para soporte de deep linking y URLs limpias en web.
// =============================================================================

class AppRoutes {
  AppRoutes._(); // Clase de utilidad — no instanciar

  // ── Nombres de rutas ────────────────────────────────────────────────────────
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  // Reservadas para futura navegación con go_router:
  static const String inventory = '/inventory';
  static const String agenda = '/agenda';
  static const String patternEditor = '/patterns/editor';
  static const String profile = '/profile';

  /// Ruta de inicio de la aplicación.
  static const String initial = login;

  // ── Mapa de rutas activas ───────────────────────────────────────────────────
  // Solo login y dashboard usan rutas nombradas actualmente.
  // Las pantallas internas del dashboard se renderizan dentro de DashboardPage.
  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginPage(),
    dashboard: (_) => const DashboardPage(),
  };

  // ── Helpers de navegación ─────────────────────────────────────────────────

  /// Navega a [route] apilando encima de la ruta actual.
  static void goTo(BuildContext context, String route) =>
      Navigator.pushNamed(context, route);

  /// Navega a [route] reemplazando la ruta actual.
  static void replaceTo(BuildContext context, String route) =>
      Navigator.pushReplacementNamed(context, route);

  /// Regresa a la pantalla anterior.
  static void goBack(BuildContext context) => Navigator.pop(context);

  /// Navega a [route] limpiando toda la pila de navegación.
  /// Útil para ir al inicio de sesión tras cerrar sesión.
  static void clearAndGoTo(BuildContext context, String route) =>
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
}
