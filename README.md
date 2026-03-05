# Configuración del Proyecto

## Firebase

Este proyecto usa Firebase. Las credenciales **no están incluidas** en el repositorio por seguridad.

### Pasos para configurar

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/).
2. Instala la CLI de FlutterFire:
   ```sh
   dart pub global activate flutterfire_cli
   ```
3. Configura el proyecto:
   ```sh
   flutterfire configure
   ```
   Esto generará automáticamente `lib/firebase_options.dart`.

4. Para Android, descarga `google-services.json` y colócalo en `android/app/`.
5. Para iOS/macOS, descarga `GoogleService-Info.plist` y colócalo en `ios/Runner/`.

### Archivos ignorados por Git

| Archivo | Razón |
|---|---|
| `lib/firebase_options.dart` | Contiene API keys |
| `android/app/google-services.json` | Credenciales Android |
| `ios/Runner/GoogleService-Info.plist` | Credenciales iOS |
| `.env` / `.env.*` | Variables de entorno |