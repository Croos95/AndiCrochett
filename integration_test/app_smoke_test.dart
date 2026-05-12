// integration_test/app_smoke_test.dart
//
// Prueba E2E (smoke) de widgets de UI sin dependencias externas (Firebase,
// SQLite). Se ejecuta con:
//
//   flutter test integration_test/app_smoke_test.dart
//
// o en un dispositivo:
//
//   flutter test integration_test/ -d chrome
//
// Verifica el flujo mínimo: el botón se monta, dispara onPressed y respeta
// el estado isLoading. Garantiza que el sistema de widgets reutilizables
// (AppButton) se mantiene utilizable extremo a extremo.

import 'package:andicrochett/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AppButton.primary se renderiza y dispara onPressed', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton.primary(
              label: 'Guardar',
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Guardar'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('AppButton con isLoading muestra spinner y bloquea taps', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton.primary(
              label: 'Guardar',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Guardar'), findsNothing); // se sustituye por el spinner

    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(taps, 0); // bloqueado por isLoading
  });

  testWidgets('AppButton.danger expone el label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.danger(label: 'Eliminar', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('Eliminar'), findsOneWidget);
  });
}
