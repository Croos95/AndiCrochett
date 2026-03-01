import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:andicrochett/core/config/routes.dart';
import 'package:andicrochett/core/config/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AndiCrochett',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
    );
  }
}