# Sprint 3 · CORS y headers de seguridad

## CORS — allowlist explícita
[`functions/index.js`](../../functions/index.js) configura CORS con una **lista blanca**, no wildcard:

```js
const allowedOrigins = (process.env.ALLOWED_ORIGINS ||
  "https://andicrochett-bcb21.web.app,http://localhost:5000")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);            // server-to-server
    if (allowedOrigins.includes(origin)) return callback(null, true);
    callback(new Error("Origin not allowed by CORS policy"));
  },
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
  credentials: false,
  maxAge: 86400,
};
```

- **`origin` callback**: rechaza explícitamente cualquier origen no listado, incluyendo `null` originado por iframes hostiles.
- **`credentials: false`**: la API usa **Bearer token**, no cookies. Esto evita el ataque "CORS + cookies de sesión".
- **`maxAge: 86400`**: cache del preflight por 24h reduce latencia sin sacrificar seguridad.
- **Override por env**: `ALLOWED_ORIGINS` permite agregar dominios (preview deployments) sin recompilar.

Cuando un origen no listado intenta una llamada, el error se enmascara como JSON limpio (no stack trace):

```js
app.use((err, req, res, next) => {
  if (err && err.message && err.message.includes("CORS")) {
    logger.warn("Blocked by CORS", { origin: req.headers.origin });
    res.status(403).json({ error: "CORS blocked" });
    return;
  }
  ...
});
```

## Helmet — headers en el lado de Cloud Functions
```js
app.disable("x-powered-by");
app.use(helmet());
```

Helmet agrega por default:
- `X-DNS-Prefetch-Control: off`
- `X-Frame-Options: SAMEORIGIN`
- `Strict-Transport-Security: max-age=15552000; includeSubDomains`
- `X-Download-Options: noopen`
- `X-Content-Type-Options: nosniff`
- `X-Permitted-Cross-Domain-Policies: none`
- `Referrer-Policy: no-referrer`
- `Content-Security-Policy: default-src 'self'`
- `Origin-Agent-Cluster: ?1`

`x-powered-by` se deshabilita explícitamente para no leakear que el backend es Express.

## Cache control en respuestas API
```js
app.use((req, res, next) => {
  res.set("Cache-Control", "no-store");
  next();
});
```

Las respuestas de la API **nunca** se cachean (ni en el browser, ni en proxies intermedios). Crítico para endpoints autenticados — un proxy compartido podría cachear `/secure/me` de un usuario y servirlo a otro.

## Headers en Firebase Hosting (lado del frontend)
[`firebase.json`](../../firebase.json) aplica seis headers a **todas** las respuestas de hosting:

| Header | Valor | Por qué |
|---|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` | Forzar HTTPS por 1 año, incluir subdominios, candidato a preload list |
| `X-Content-Type-Options` | `nosniff` | El navegador no debe "adivinar" el MIME type |
| `X-Frame-Options` | `DENY` | La app NO se puede embeber en iframe — previene clickjacking |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | No filtrar paths a sitios externos |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=(), payment=()` | Bloquear APIs sensibles del navegador |
| `Content-Security-Policy` | `default-src 'self' https: data: blob:; base-uri 'self'; frame-ancestors 'none'; object-src 'none'; upgrade-insecure-requests` | Restringir orígenes de recursos, bloquear `<object>`, forzar HTTPS |

`frame-ancestors 'none'` en CSP refuerza `X-Frame-Options: DENY` para navegadores modernos.

## Validación manual

### Probar CORS:
```sh
# Origen permitido (debe devolver 200 + headers Access-Control-*)
curl -i -H "Origin: http://localhost:5000" http://localhost:5001/.../api/health

# Origen no permitido (debe devolver 403 CORS blocked)
curl -i -H "Origin: https://evil.com" http://localhost:5001/.../api/health
```

### Probar headers de Hosting:
```sh
curl -I https://andicrochett-bcb21.web.app/
# Debe mostrar strict-transport-security, content-security-policy, etc.
```

### Validador online
- [securityheaders.com](https://securityheaders.com/?q=https://andicrochett-bcb21.web.app) — calificación esperada: **A** o mejor.
- [Mozilla Observatory](https://observatory.mozilla.org/analyze/andicrochett-bcb21.web.app).
