# Auth

Este modulo centraliza el inicio de sesion, registro, cierre de sesion y recuperacion de contrasena con Firebase Authentication.

## Como esta implementado

### Capa de datos
- [lib/features/auth/data/repositories/auth_repository.dart](lib/features/auth/data/repositories/auth_repository.dart) encapsula `FirebaseAuth`.
- Expone `signInWithEmail`, `registerWithEmail`, `signOut`, `sendPasswordReset` y `authStateChanges`.
- `authStateChanges` mantiene sincronizado el estado de la sesion de Firebase en tiempo real.

### Capa de estado
- [lib/features/auth/presentation/providers/auth_provider.dart](lib/features/auth/presentation/providers/auth_provider.dart) escucha `authStateChanges`.
- Convierte el estado de Firebase en `AuthStatus` para la UI.
- Tambien traduce errores a mensajes legibles usando `AuthRepository.messageFromCode`.

### Perfil de usuario
- [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart) coordina FirebaseAuth con Firestore.
- Crea, actualiza y elimina el documento de perfil en `users/{uid}`.

## Seguridad de web

### Headers
- [firebase.json](firebase.json) agrega headers globales en Firebase Hosting.
- Se incluyen `HSTS`, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy` y `Content-Security-Policy`.

### CORS
- La API vive en Firebase Functions en [functions/index.js](functions/index.js).
- CORS usa una lista blanca definida por `ALLOWED_ORIGINS`.
- Se permiten `Content-Type`, `Authorization` y `X-Requested-With`.
- El endpoint principal esta montado bajo `/api` y el healthcheck responde en `/api/health`.

### HTTPS
- [web/index.html](web/index.html) redirige automaticamente a HTTPS si la app no se abre desde `localhost`.
- [lib/core/config/env.dart](lib/core/config/env.dart) exige `https://` en `BASE_URL` cuando compilas en produccion.

## Flujo resumido

1. El usuario inicia sesion con email y contrasena.
2. Firebase Authentication valida credenciales y emite el estado autenticado.
3. El provider escucha el cambio y actualiza la UI.
4. El perfil adicional se sincroniza en Firestore cuando aplica.

## Notas

- Firebase maneja tokens de autenticacion internamente.
- No hay sesiones de servidor tradicionales en este modulo.
- Si despliegas web, usa siempre un origen HTTPS.
