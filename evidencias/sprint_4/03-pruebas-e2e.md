# Sprint 4 · Pruebas E2E

Las pruebas E2E ahora viven en dos sitios:

1. **[`test/e2e/`](../../test/e2e/)** — E2E lógico: mockea la capa HTTP con `MockClient` y valida el flujo completo desde JSON-de-backend hasta render-de-UI. Corre con `flutter test` sin device.
2. **[`integration_test/`](../../integration_test/)** — E2E sobre el binding real de Flutter; requiere device (Android emulator o desktop habilitado).

Esta división evita el clásico problema de "los E2E solo corren en mi máquina con un emulador encendido": el bloque #1 entra en CI sin fricción, el bloque #2 queda para validación manual antes de release.

## Cobertura — `test/e2e/`

### [`analytics_dashboard_e2e_test.dart`](../../test/e2e/analytics_dashboard_e2e_test.dart) (2 tests)

Valida la pantalla más representativa del Sprint 5 (dashboard de analítica):

| Test | Qué valida |
|---|---|
| `flujo completo: loading → datos de negocio → seguridad → reload` | Loading inicial muestra spinner, después de la respuesta JSON aparecen las 6 tarjetas de negocio + top productos + lista "por reabastecer", cambio de tab a Seguridad renderiza 4 tarjetas de login attempts + 5 de API calls + endpoints más usados + logins fallidos, el botón "Recargar" dispara nuevo fetch |
| `si el backend devuelve 500 muestra el mensaje de error` | El path de error propaga el mensaje del backend (`{error: "BD caída"}` → "Error al cargar métricas: BD caída") en lugar de un genérico |

**¿Por qué éstos y no otros?** El dashboard es el centro del Sprint 5 y combina:
- Capa HTTP (`ApiClient`).
- Parseo del DTO (`AnalyticsRepository`).
- Estado y FutureBuilder.
- Navegación por tabs.
- Render condicional (loading / error / data / empty).

Cubrirlo de extremo a extremo da más valor por test que cubrir un botón aislado.

## Cobertura — `integration_test/`

### [`app_smoke_test.dart`](../../integration_test/app_smoke_test.dart) (3 tests)

Smoke test del widget reutilizable `AppButton` sobre el binding real:

| Test | Qué valida |
|---|---|
| `AppButton.primary se renderiza y dispara onPressed` | Monta label, responde a `tap`, dispara callback una vez |
| `AppButton con isLoading muestra spinner y bloquea taps` | Sustituye label por `CircularProgressIndicator`, taps quedan deshabilitados |
| `AppButton.danger expone el label` | Constructor `.danger` también renderiza |

## Técnica clave: mocking sin Firebase

El reto de E2E en una app que usa Firebase Auth es que el binding necesita Firebase inicializado, lo cual requiere `google-services.json` y red. En `test/e2e/` lo evitamos con **inyección por constructor**:

```dart
// El AnalyticsRepository acepta un ApiClient inyectable.
final repo = AnalyticsRepository(
  api: ApiClient(
    baseUrl: 'http://test.local/api',
    client: MockClient((req) async {
      if (req.url.path.endsWith('/dashboard')) {
        return http.Response(jsonEncode(_dashboardJson), 200, ...);
      }
      // ...
    }),
    tokenProvider: () async => 'fake-token',  // ← evita Firebase Auth
  ),
);

await tester.pumpWidget(MaterialApp(
  home: AnalyticsDashboardPage(repository: repo),
));
```

- `MockClient` de `http/testing.dart` intercepta cada request y devuelve la respuesta canned.
- `tokenProvider` opcional en `ApiClient` reemplaza la llamada a `FirebaseAuth.currentUser.getIdToken()`.
- El `MaterialApp` se pumpa directo, sin pasar por `main()` ni inicializar `Firebase.initializeApp()`.

Resultado: el test ejercita la cadena completa **HTTP → parsing → state → UI → interacción** sin depender de servicios externos.

## Cómo ejecutarlas

```sh
# E2E lógico (sin device, corre en CI)
flutter test test/e2e/

# E2E binding-bound (requiere device)
flutter test integration_test/ -d <device>
# devices posibles: android (emulator/dispositivo), windows (si está habilitado)
```

Web e iOS-simulator no están soportados por `integration_test` por ahora — usa Android emulator o desktop.

## Limitaciones conocidas

- Los E2E de `test/e2e/` no ejercitan el binding nativo (animaciones complejas, gestos de scroll grandes pueden comportarse distinto en device).
- Los E2E de `integration_test/` no corren en CI por defecto (necesitarían un emulador en GitHub Actions, lo cual encarece la pipeline).
- No hay aún un E2E que valide login real contra Firebase — saltaríamos a un `firebase_auth_mocks` o emulador local de Firebase Auth.

## Roadmap de extensión

1. E2E de `DesignsPage`: crear → ver en grid → editar → borrar (con `MockClient`).
2. E2E de `InventoryPage`: agregar producto → ajustar stock → verificar contador en dashboard.
3. E2E de `AgendaPage`: crear pedido → cambiar estado → cancelar (descuento/devolución de stock).
4. Configurar Android emulator headless en el job CI para correr `integration_test/` automáticamente.
