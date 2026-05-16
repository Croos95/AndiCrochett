# Sprint 3 · JWT middleware

## El contrato
Casi todas las rutas del backend exigen:

```
Authorization: Bearer <Firebase ID Token>
```

El token lo emite Firebase Auth en el cliente con `user.getIdToken()`. Es un **JWT real**: firmado por Google, con expiración de 1 hora y rotación de claves automática.

**Excepciones (rutas públicas)**:
- `GET /health` — liveness check
- `POST /api/security/login-attempt` — necesariamente pública porque los intentos fallidos no tienen token aún

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

[`backend/src/auth.js`](../../backend/src/auth.js):

```js
async function verifyFirebaseToken(req, res, next) {
  const header = req.headers.authorization || '';
  const match = header.match(/^Bearer (.+)$/);

  if (!match) {
    return res.status(401).json({ error: 'Token de autorización faltante' });
  }

  // Bypass para tests (solo si NODE_ENV=test):
  // cualquier token "test-<uid>" se acepta y se decodifica como usuario sintético.
  if (process.env.NODE_ENV === 'test' && match[1].startsWith('test-')) {
    req.user = {
      uid: match[1].slice('test-'.length) || 'test-user',
      email: 'test@example.com',
      emailVerified: true,
    };
    return next();
  }

  if (!admin.apps.length) {
    return res.status(500).json({ error: 'Backend sin credenciales de Firebase' });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(match[1]);
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      emailVerified: decoded.email_verified,
    };
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Token inválido o expirado' });
  }
}
```

Puntos clave del diseño:

1. **`req.user` adjunto al request** — los handlers reciben `uid`, `email`, `emailVerified` sin volver a parsear.
2. **Bypass para tests** detrás de `NODE_ENV=test` — imposible activarlo en producción. Permite a `supertest` simular usuarios sin Firebase real.
3. **Inicialización lazy** — si el `firebase-service-account.json` no está, el middleware responde 500 con mensaje claro en vez de tirar al arranque.

## Aplicación

[`backend/src/app.js`](../../backend/src/app.js):

```js
const { verifyFirebaseToken } = require('./auth');

// Cada router protegido aplica el middleware:
app.use('/api/patterns', patternsRouter);   // patterns.js usa verifyFirebaseToken
app.use('/api/designs', designsRouter);
app.use('/api/products', productsRouter);
// ...

// La única ruta pública (excepto /health):
app.use('/api/security', securityRouter);   // POST /login-attempt sin middleware
```

Dentro de cada router:
```js
// backend/src/routes/designs.js
const router = express.Router();
router.use(verifyFirebaseToken);
```

## El uid sale del token, no del body

Decisión importante: **el cliente NUNCA manda su propio `usuario_id`**. Todo lo que escribe el backend con `usuario_id` lo toma de `req.user.uid` (post-verificación). Esto previene que un usuario manipule el body para crear datos a nombre de otro.

```js
// backend/src/routes/designs.js
router.post('/', (req, res) => {
  const { nombre, descripcion } = req.body;
  // ...
  db.prepare(`INSERT INTO designs ... VALUES (?, ?, ?, ...)`)
    .run(nombre, descripcion, req.user.uid, now, now);
                                  // ↑ del token, no del body
});
```

## Pruebas

[`backend/test/smoke.test.js`](../../backend/test/smoke.test.js) cubre el middleware indirectamente vía las rutas protegidas:

| Test | Verifica |
|---|---|
| `GET /api/designs sin auth → 401` | Header faltante → 401 |
| `GET /api/designs con token de prueba → 200` | `test-user-1` → bypass exitoso |
| `POST /api/designs crea y luego GET lo devuelve` | `req.user.uid` se inyecta correctamente en el INSERT |
| `POST /api/security/login-attempt es público` | Confirma que las rutas excluidas no aplican el middleware |

## Flujo end-to-end

```
[Flutter app]
    ↓ user.getIdToken()  (Firebase SDK)
    ↓
"eyJhbGc..."
    ↓ Authorization: Bearer eyJhbGc...     (ApiClient inyecta automático)
    ↓
[Backend Express :3000 o :3443]
    ↓
[helmet]                → headers de seguridad
[cors]                  → valida origen
[auditMiddleware]       → registra en audit_log al finalizar
[verifyFirebaseToken]
    ↓ admin.auth().verifyIdToken("eyJhbGc...")
    ↓ ✔ válido → req.user = { uid, email, ... }
    ↓ ✘ inválido → 401 + body { error: "Token inválido o expirado" }
[handler]
    ↓ res.json({...})
[response]
    ↓ se loguea audit_log con status_code, duration_ms, uid
```

## Errores comunes

- **401 + "Token inválido o expirado"**: el cliente usa un token > 1h o de otro proyecto Firebase. Llama `getIdToken(true)` para forzar refresh.
- **401 + "Token de autorización faltante"**: el `ApiClient` no fue inicializado o el usuario hizo logout. Verificar `FirebaseAuth.instance.currentUser != null`.
- **500 + "Backend sin credenciales de Firebase"**: falta el `firebase-service-account.json` en el backend. Ver [README del backend](../../backend/README.md).
