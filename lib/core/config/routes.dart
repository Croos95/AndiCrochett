import 'package:flutter/material.dart';
import 'package:andicrochett/features/auth/presentation/pages/login_page.dart';
import 'package:andicrochett/features/dashboard/presentation/pages/dashboard_page.dart';

class AppRoutes {
  // Nombres de rutas
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String inventory = '/inventory';
  static const String agenda = '/agenda';
  static const String patternEditor = '/patterns/editor';
  static const String profile = '/profile';

  // Ruta inicial
  static const String initial = login;

  // Mapa de rutas
  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginPage(),
    dashboard: (_) => const DashboardPage(),
    //inventory: (_) => const InventoryPage(),
    //agenda: (_) => const AgendaPage(),
    //patternEditor: (_) => const PatternEditorPage(),
    //profile: (_) => const ProfilePage(),
  };

  // Navegación con nombre
  static void goTo(BuildContext context, String route) =>
      Navigator.pushNamed(context, route);

  static void replaceTo(BuildContext context, String route) =>
      Navigator.pushReplacementNamed(context, route);

  static void goBack(BuildContext context) => Navigator.pop(context);

  static void clearAndGoTo(BuildContext context, String route) =>
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
}
