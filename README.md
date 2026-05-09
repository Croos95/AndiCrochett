# AndiCrochett

App Flutter conectada a Firebase para auth, agenda, inventario, diseños y patrones.

## Requisitos

- Flutter SDK
- Firebase CLI
- Proyecto Firebase configurado con `flutterfire configure`

## Configuracion rapida

1. Crea o usa un proyecto en Firebase.
2. Ejecuta:
   ```sh
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. Verifica que existan las credenciales de Android e iOS/macOS.

## Ejecutar

```sh
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 5000
```

## Seguridad web

- `web/index.html` fuerza HTTPS fuera de `localhost`.
- `firebase.json` aplica headers de seguridad en Hosting.
- `functions/index.js` expone la API con CORS restringido.

## API segura

- Base API: `/api`
- Healthcheck: `/api/health`
- Origenes permitidos: `ALLOWED_ORIGINS`

## Archivos clave

- [web/index.html](web/index.html)
- [firebase.json](firebase.json)
- [functions/index.js](functions/index.js)
- [lib/core/config/env.dart](lib/core/config/env.dart)