# Sprint 3 — Seguridad

## Descripción del sprint
Sprint dedicado a cerrar la capa de seguridad del **backend Node propio** y del **cliente Flutter**: validación de **JWT** vía Firebase ID tokens, **CORS** estricto, **headers de seguridad** vía Helmet, **HTTPS local** opt-in con cert auto-firmado, y **auditoría completa** (`audit_log` + endpoint público de login attempts) que alimenta el dashboard del Sprint 5.

> **Nota histórica**: la versión original de este sprint apuntaba a Firebase Cloud Functions con rutas `/api/secure/*`. Tras la migración del proyecto, todo el backend vive ahora en `backend/` (Node + Express + better-sqlite3 + Helmet). Los conceptos y validaciones siguen vigentes — cambia el dónde, no el qué.

## Objetivo
- Que ninguna ruta del backend (excepto `/health` y `POST /api/security/login-attempt`) acepte requests sin un Firebase ID token válido.
- Que el navegador rechace por política cualquier origen no listado.
- Que la app Flutter envíe automáticamente el `Authorization: Bearer <token>` en cada request.
- Que el backend pueda correr en HTTPS local con un comando (`npm run dev:https`).
- Que cada request quede registrada en `audit_log` para forensia y métricas.

## Tecnologías utilizadas
- **`firebase-admin`** — verifica ID tokens emitidos por Firebase Auth.
- **`express`** + **`helmet`** + **`cors`** — pipeline HTTP del backend.
- **`selfsigned`** — genera el cert auto-firmado para HTTPS local.
- **`http`** + **`firebase_auth`** en Dart — cliente HTTP general (`ApiClient`) con `tokenProvider` inyectable.

## Estructura entregada
```
backend/src/
├── app.js                          ← pipeline Express + helmet + cors + audit
├── server.js                       ← arranca HTTP (siempre) y HTTPS (si HTTPS_PORT)
├── https.js                        ← ensureCert() — genera/lee cert auto-firmado
├── auth.js                         ← verifyFirebaseToken (con bypass para NODE_ENV=test)
├── middleware/
│   └── audit.js                    ← persiste cada request en audit_log
└── routes/
    └── security.js                 ← POST /login-attempt (público)

lib/core/services/
├── api_client.dart                 ← cliente HTTP general con tokenProvider
└── security_reporter.dart          ← reporta login attempts al backend

android/app/src/main/res/xml/
└── network_security_config.xml     ← cleartext permitido solo para dev hosts
```

## Documentación detallada
1. [JWT middleware](01-jwt-middleware.md)
2. [HTTPS local + producción](02-https-local.md)
3. [CORS + headers de seguridad](03-cors-headers.md)
4. [Cliente Dart seguro](04-cliente-dart-seguro.md)

## Cómo probarlo localmente

```sh
# 1. Backend con HTTPS habilitado
cd backend
npm run dev:https           # arranca HTTP:3000 + HTTPS:3443

# 2. Otra terminal — petición sin token (debe responder 401)
curl -i http://localhost:3000/api/designs

# 3. Verificar headers de helmet sobre HTTPS
curl -k -I https://localhost:3443/health
# Expect: Strict-Transport-Security: max-age=31536000; includeSubDomains
#         X-Content-Type-Options: nosniff
#         X-Frame-Options: SAMEORIGIN
#         (...10 headers en total)

# 4. Token válido (obtener desde la app Flutter):
#    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
curl -i http://localhost:3000/api/designs \
  -H "Authorization: Bearer <id-token-de-firebase>"
```

## Pruebas

```sh
cd backend
npm test
```

Cobertura específica del sprint:
- `GET /api/designs sin auth → 401` — middleware bloquea
- `GET /api/designs con token de prueba → 200` — bypass en NODE_ENV=test
- `POST /api/security/login-attempt es público y registra` — ruta pública
- `GET /api/analytics/security agrega login_attempts y api_calls` — audit_log se llena

12/12 tests pasando.

## Criterios cumplidos
| Criterio del PDF | Entregado |
|---|---|
| Login con JWT o sesiones | Firebase Auth emite ID tokens (JWT); [`verifyFirebaseToken`](../../backend/src/auth.js) los valida en cada request a `/api/*` (excepto health y login-attempt) |
| HTTPS local | `npm run dev:https` levanta HTTPS en `:3443` con cert auto-firmado (cubre localhost, 127.0.0.1, 10.0.2.2 para Android emulator). En producción `Env.baseUrl` exige `https://` |
| Configuración de CORS y headers | CORS allowlist en [`backend/src/app.js`](../../backend/src/app.js) + 10 headers de seguridad vía Helmet (`Strict-Transport-Security`, `X-Frame-Options`, `Referrer-Policy`, `X-Content-Type-Options`, etc.) |

## Extras del sprint (más allá de lo pedido)
- **`audit_log`** — bitácora completa de requests + intentos de login que alimenta el dashboard de Seguridad (Sprint 5).
- **`network_security_config.xml`** — Android: cleartext permitido solo para hosts de dev (`10.0.2.2`, `localhost`, `127.0.0.1`); en producción todo es HTTPS obligado.
- **Bypass de auth en tests** (`NODE_ENV=test` + tokens `test-<uid>`) — permite CI sin credenciales reales de Firebase.
