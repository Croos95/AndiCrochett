import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:andicrochett/core/config/routes.dart';
import 'package:andicrochett/core/config/theme.dart';
import 'package:andicrochett/core/services/analytics_service.dart';
import 'package:andicrochett/features/auth/presentation/providers/auth_provider.dart';
import 'package:andicrochett/features/inventory/presentation/providers/inventory_provider.dart';
import 'firebase_options.dart';

late final GoRouter _router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final analyticsObserver = _configureAnalytics();

  final authProvider = AuthProvider();
  _router = AppRoutes.createRouter(
    authProvider,
    observers: analyticsObserver == null ? const [] : [analyticsObserver],
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

/// Conecta los sinks de analytics y devuelve el observer de navegación que
/// registra screen views automáticamente. Si Firebase Analytics no está
/// disponible (ej. plataforma sin soporte), regresa `null` y la app sigue
/// funcionando con el sink de consola.
FirebaseAnalyticsObserver? _configureAnalytics() {
  try {
    final firebaseSink = FirebaseAnalyticsSink();
    AnalyticsService.instance.configure([
      ConsoleAnalyticsSink(),
      firebaseSink,
    ]);

    // Mantiene el UID actualizado cada vez que cambia la sesión.
    FirebaseAuth.instance.userChanges().listen((user) {
      firebaseSink.setUserId(user?.uid);
    });

    return FirebaseAnalyticsObserver(analytics: firebaseSink.analytics);
  } catch (e, st) {
    debugPrint('[analytics] no se pudo inicializar FirebaseAnalyticsSink: $e\n$st');
    return null;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AndiCrochett',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
