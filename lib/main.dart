import 'package:flutter/material.dart';
import 'package:andicrochett/core/config/routes.dart';
import 'package:andicrochett/core/config/theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AndiCrochett',
      debugShowCheckedModeBanner: false, //Desactivar en producción
      theme: AppTheme.light,
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
    );
  }
}
