import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:andicrochett/core/config/routes.dart';
import 'package:andicrochett/core/config/theme.dart';
import 'package:andicrochett/features/auth/presentation/providers/auth_provider.dart';
import 'package:andicrochett/features/auth/presentation/pages/login_page.dart';
import 'package:andicrochett/features/dashboard/presentation/pages/dashboard_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AndiCrochett',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routes: AppRoutes.routes,
      home: const _AuthGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AuthGate — redirige según el estado de autenticación
// ─────────────────────────────────────────────────────────────────────────────
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthProvider>().status;

    return switch (authStatus) {
      AuthStatus.authenticated => const DashboardPage(),
      AuthStatus.initial || AuthStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      _ => const LoginPage(),
    };
  }
}
