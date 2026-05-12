# Sprint 3 · JWT middleware

## El contrato
Cualquier ruta montada bajo `/secure/*` exige:

```
Authorization: Bearer <Firebase ID Token>
```

El token lo emite Firebase Auth en el cliente con `user.getIdToken()`. Es un **JWT real**: firmado, con expiración de 1 hora y rotación de claves automática del lado de Google.

## Por qué Firebase ID token y no un JWT custom
| Si emitiéramos JWT propios | Con Firebase ID token |
|---|---|
| Necesitamos un keystore | Google lo administra |
| Implementar rotación de claves | Automática |
| Implementar refresh | `getIdToken(true)` |
| Implementar revocación | `revokeRefreshTokens` |
| Sesiones extra en BD | No |

Reusamos la infra que ya teníamos para auth y obtenemos rotación + revocación gratis.

## Implementación

[`functions/middleware/auth.js`](../../functions/middleware/auth.js):

```js
function authenticate(opts = {}) {
  const verify = opts.verifyIdToken
    || ((token) => admin.auth().verifyIdToken(token));

  return async (req, res, next) => {
    const header = req.get("Authorization") || "";
    if (!header.startsWith("Bearer ")) {
      return res.status(401).json({ error: "missing_bearer_token", ... });
    }
    const token = header.slice("Bearer ".length).trim();
    if (!token) return res.status(401).json({ error: "empty_bearer_token", ... });

    try {
      const decoded = await verify(token);
      req.user = { uid: decoded.uid, email: decoded.email, ... };
      next();
    } catch (err) {
      return res.status(401).json({ error: "invalid_token", code: err.code, ... });
    }
  };
}
```

Puntos clave del diseño:

1. **Factory pattern**: `authenticate()` devuelve el middleware. Permite inyectar `verifyIdToken` en pruebas sin tocar Firebase real.
2. **Respuestas tipadas**: `missing_bearer_token` / `empty_bearer_token` / `invalid_token` permiten al cliente distinguir entre "olvidaste el header" vs "el token expiró".
3. **`req.user`** adjunto al request — los handlers reciben `uid`, `email`, `emailVerified`, `authTime` sin volver a parsear.

## Aplicación
En [`functions/index.js`](../../functions/index.js):

```js
const secure = express.Router();
secure.use(authenticate());

secure.get("/me", (req, res) => res.json({ user: req.user }));
secure.get("/ping", (req, res) => res.json({ ok: true, uid: req.user.uid }));

app.use("/secure", secure);
```

Rutas resultantes:
- `GET /api/secure/me` → devuelve el usuario actual.
- `GET /api/secure/ping` → healthcheck autenticado.

Las rutas públicas (`/api/health`) quedan intactas.

## Pruebas
[`functions/test/auth.test.js`](../../functions/test/auth.test.js) usa `node:test` (built-in, sin deps) e inyecta un `verifyIdToken` mock:

| Test | Verifica |
|---|---|
| rechaza request sin header Authorization | 401 + `missing_bearer_token` |
| rechaza header sin prefijo Bearer | 401 + `missing_bearer_token` |
| rechaza Bearer vacío | 401 + `empty_bearer_token` |
| rechaza cuando el verificador lanza | 401 + `invalid_token` + código del SDK |
| acepta token válido y adjunta req.user | 200 + body con `uid`/`email`/`emailVerified` |

**5/5 pasan.** Corren en CI dentro del job `functions-lint` (renombrar mentalmente — ahora también ejecuta `npm test`).

## Flujo end-to-end

```
[Flutter app]
    ↓ user.getIdToken()
    ↓
"eyJhbGc..."
    ↓ Authorization: Bearer eyJhbGc...
    ↓
[Express /api/secure/me]
    ↓
[helmet]  → headers de seguridad
[cors]    → valida origen
[authenticate()]
    ↓ admin.auth().verifyIdToken("eyJhbGc...")
    ↓ ✔ válido → req.user = {...}
    ↓ ✘ inválido → 401 invalid_token
[handler]
    ↓ res.json({ user: req.user })
```

## Errores comunes

- **401 invalid_token + `auth/id-token-expired`**: el cliente está usando un token > 1h. Llama `getIdToken(true)` para forzar refresh.
- **401 missing_bearer_token**: el cliente no envió el header. Verificar que `SecureApiClient` esté siendo usado.
- **403 CORS blocked**: el origen no está en `ALLOWED_ORIGINS`. Ver [03-cors-headers.md](03-cors-headers.md).
