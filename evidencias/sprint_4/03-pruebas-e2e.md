# Sprint 4 · Pruebas E2E

Las pruebas E2E viven en [`integration_test/`](../../integration_test/) y se ejecutan con el binding real de Flutter (`IntegrationTestWidgetsFlutterBinding`). A diferencia de los tests unitarios de widget, estos pueden correr en un dispositivo (Chrome, Windows, Android) y exponen la app a interacciones reales.

## Por qué E2E
Las pruebas unitarias verifican unidades aisladas; las E2E verifican que **el binding completo de Flutter funciona** — render, animaciones, gestos, layout — y que los widgets reutilizables siguen siendo usables extremo a extremo.

## Cobertura

[`app_smoke_test.dart`](../../integration_test/app_smoke_test.dart):

| Test | Qué valida |
|---|---|
| `AppButton.primary se renderiza y dispara onPressed` | El botón monta el label, responde a `tap`, dispara el callback una sola vez. |
| `AppButton con isLoading muestra spinner y bloquea taps` | En estado de carga sustituye el label por `CircularProgressIndicator` y `onPressed` queda deshabilitado (taps = 0). |
| `AppButton.danger expone el label` | El constructor `.danger` también renderiza el label correctamente. |

**Total: 3 tests E2E.**

## Por qué empezamos con `AppButton`
Es el widget reutilizable más cargado de la app: tiene 4 variantes (`primary`, `secondary`, `danger`, `outlined`), un estado `isLoading` con lógica de bloqueo, e iconografía opcional. Si rompe, toda la UI rompe. Es el candidato natural para ser el primer E2E.

## Cómo ejecutarlas
```sh
# En Chrome (web)
flutter test integration_test/ -d chrome

# En Windows (desktop)
flutter test integration_test/ -d windows

# Headless (CI ligero, no recomendado para flujos con animaciones)
flutter test integration_test/
```

## Limitaciones conocidas
- Los E2E **no** corren todavía un flujo completo de login → dashboard porque dependerían de Firebase y de la red. Para extenderlos a flujos con Firebase se necesitaría inicializar `firebase_core` con `FirebaseAppMock` o un emulador de Firebase Auth.
- El CI por ahora no ejecuta `integration_test/` (necesita configurar device en el job de GitHub Actions). Sí los corre `flutter test test/`.

## Roadmap de extensión
1. Mock de `FirebaseAuth` para probar flujo de login.
2. Smoke test del dashboard con `InventoryProvider` en memoria.
3. Flujo completo de creación de pedido (mock de SQLite).
