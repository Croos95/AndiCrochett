# Sprint 3 — Seguridad

## Descripción del sprint
Sprint dedicado a cerrar la capa de seguridad del backend y del cliente: validación de **JWT** vía Firebase ID tokens, **CORS** estricto con allowlist, **headers de seguridad** completos en Hosting, y **HTTPS** forzado en producción. Se entrega también un cliente Dart que cablea el token en cada request.

## Objetivo
- Que ninguna ruta `/secure/*` del backend acepte requests sin un Firebase ID token válido.
- Que el navegador rechace por política cualquier origen no listado.
- Que la app Flutter envíe automáticamente el `Authorization: Bearer <token>` en sus llamadas.

## Tecnologías utilizadas
- **Firebase Admin SDK** (`firebase-admin`) — verifica ID tokens emitidos por Firebase Auth.
- **Express** + **CORS** + **Helmet** — pipeline HTTP del backend.
- **Firebase Hosting** — termina TLS en producción y emite los headers de seguridad de `firebase.json`.
- **`http`** package en Dart — cliente HTTP para `SecureApiClient`.

## Estructura entregada
```
functions/
├── index.js                  ← rutas / pipeline / aplica el middleware
├── middleware/
│   └── auth.js               ← valida Firebase ID token (JWT)
├── test/
│   └── auth.test.js          ← 5 tests del middleware (node:test)
└── package.json              ← scripts test + lint, dep firebase-admin

lib/core/services/
└── secure_api_client.dart    ← cliente Dart con Bearer auto-inyectado
```

## Documentación detallada
1. [JWT middleware](01-jwt-middleware.md)
2. [HTTPS local + producción](02-https-local.md)
3. [CORS + headers de seguridad](03-cors-headers.md)
4. [Cliente Dart seguro](04-cliente-dart-seguro.md)

## Cómo probarlo localmente
```sh
# 1. Emulador de Functions + Hosting
firebase emulators:start --only functions,hosting

# 2. En otra terminal: petición sin token (debe responder 401)
curl -i http://localhost:5000/api/secure/me

# 3. Petición con token válido (obtener del cliente)
curl -i http://localhost:5000/api/secure/me \
  -H "Authorization: Bearer <id-token-de-firebase>"
```

## Pruebas
```sh
cd functions
npm test
```
Salida:
```
✔ rechaza request sin header Authorization
✔ rechaza header sin prefijo Bearer
✔ rechaza Bearer vacío
✔ rechaza cuando el verificador lanza
✔ acepta token válido y adjunta req.user
ℹ tests 5  pass 5  fail 0
```

## Criterios cumplidos
| Criterio del PDF | Entregado |
|---|---|
| Login con JWT o sesiones | Firebase Auth emite ID tokens (JWT); el middleware [`auth.js`](../../functions/middleware/auth.js) los valida en cada request a `/secure/*` |
| HTTPS local | `web/index.html` redirige a HTTPS fuera de localhost; `Env.baseUrl` exige `https://` en producción |
| Configuración de CORS y headers | CORS allowlist en `functions/index.js` + 6 headers de seguridad en `firebase.json` (HSTS, CSP, X-Frame-Options, etc.) |
