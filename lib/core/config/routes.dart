import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:andicrochett/features/analytics/presentation/pages/analytics_dashboard_page.dart';
import 'package:andicrochett/features/auth/presentation/pages/login_page.dart';
import 'package:andicrochett/features/auth/presentation/pages/register_page.dart';
import 'package:andicrochett/features/auth/presentation/providers/auth_provider.dart';
import 'package:andicrochett/features/dashboard/presentation/pages/dashboard_page.dart';

// =============================================================================
//  AppRoutes
//  Define todas las rutas nombradas de la aplicación y el GoRouter.
//
//  go_router maneja deep linking, URLs limpias en web y redirecciones
//  basadas en autenticación mediante refreshListenable + redirect callback.
//
//  La navegación entre pantallas principales (inventory, patterns, designs)
//  se realiza mediante el sidebar del DashboardPage, no mediante rutas nombradas.
//  Las rutas nombradas solo se usan para las transiciones de autenticación.
// =============================================================================

class AppRoutes {
  AppRoutes._(); // Clase de utilidad — no instanciar

  // ── Nombres de rutas ────────────────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String analytics = '/analytics';

  // ── Router factory ──────────────────────────────────────────────────────────
  /// Crea el [GoRouter] de la app. Llamar una vez al inicio y reutilizar.
  ///
  /// El [AuthProvider] actúa como [refreshListenable]: cada vez que cambia
  /// el estado de autenticación go_router re-evalúa el redirect automáticamente.
  ///
  /// [observers] permite inyectar `NavigatorObserver`s (por ejemplo el
  /// `FirebaseAnalyticsObserver`) para tracking automático de pantallas.
  static GoRouter createRouter(
    AuthProvider authProvider, {
    List<NavigatorObserver> observers = const [],
  }) => GoRouter(
    initialLocation: login,
    refreshListenable: authProvider,
    observers: observers,
    redirect: (_, state) {
      final loggedIn = authProvider.isAuthenticated;
      final onLogin = state.matchedLocation == login;
      final onRegister = state.matchedLocation == register;
      if (loggedIn && (onLogin || onRegister)) return dashboard;
      if (!loggedIn && !onLogin && !onRegister) return login;
      return null;
    },
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: dashboard,
        name: 'dashboard',
        builder: (_, __) => const DashboardPage(),
      ),
      GoRoute(
        path: analytics,
        name: 'analytics',
        builder: (_, __) => const AnalyticsDashboardPage(),
      ),
    ],
  );
}
