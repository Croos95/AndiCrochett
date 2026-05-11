import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:andicrochett/core/config/routes.dart';
import 'package:andicrochett/core/config/theme.dart';
import 'package:andicrochett/features/auth/presentation/providers/auth_provider.dart';
import 'package:andicrochett/features/inventory/presentation/providers/inventory_provider.dart';
import 'firebase_options.dart';

late final GoRouter _router;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ¡Adiós al initializeSqflite()! En móvil no se necesita.

  final authProvider = AuthProvider();
  _router = AppRoutes.createRouter(authProvider);

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