# Sprint 3 · CORS y headers de seguridad

## CORS — configurable vía env

[`backend/src/app.js`](../../backend/src/app.js) configura CORS:

```js
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
```

Por defecto en desarrollo acepta cualquier origen (`*`) — necesario porque el emulador Android pega desde un origen sintético y Flutter web puede ir desde `chrome-extension://` durante debug.

En producción se restringe con `.env`:
```env
CORS_ORIGIN=https://andicrochett-bcb21.web.app
```

O para multi-origen, intercambiar a una callback function en `app.js`:
```js
const allowedOrigins = process.env.CORS_ORIGIN?.split(',') || [];
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
    callback(new Error('Origin not allowed by CORS policy'));
  },
}));
```

La autenticación va por **Bearer token**, no cookies, así que `credentials: false` es lo seguro (evita el ataque clásico "CORS + cookies de sesión").

## Helmet — 10 headers de seguridad inyectados

[`backend/src/app.js`](../../backend/src/app.js):

```js
const helmet = require('helmet');

app.use(helmet({
  contentSecurityPolicy: false,                         // API JSON no sirve HTML
  crossOriginResourcePolicy: { policy: 'cross-origin' }, // permite consumo desde Flutter web
}));
```

Verificación contra el endpoint real:
```sh
curl -k -I https://localhost:3443/health
```

Output:
```http
HTTP/1.1 200 OK
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: cross-origin
Origin-Agent-Cluster: ?1
Referrer-Policy: no-referrer
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-DNS-Prefetch-Control: off
X-Download-Options: noopen
X-Frame-Options: SAMEORIGIN
X-Permitted-Cross-Domain-Policies: none
X-XSS-Protection: 0
Access-Control-Allow-Origin: *
```

### Por qué cada header

| Header | Para qué |
|---|---|
| `Strict-Transport-Security` | Cuando llega por HTTPS, indica al navegador "no vuelvas a usar HTTP por 1 año". Solo aplica sobre TLS real. |
| `X-Content-Type-Options: nosniff` | El navegador no debe "adivinar" el MIME — si dijiste `application/json`, eso es. |
| `X-Frame-Options: SAMEORIGIN` | La API no se puede embeber en iframe de otro dominio (anti-clickjacking, aunque para una API JSON es defensa profunda). |
| `Referrer-Policy: no-referrer` | No filtres el path actual a sitios externos. |
| `Cross-Origin-Resource-Policy: cross-origin` | Explícito que la API SÍ puede consumirse desde otros orígenes (lo necesita Flutter web). |
| `Cross-Origin-Opener-Policy: same-origin` | El popup de OAuth de Google se cierra correctamente sin "fugar" referencias. |
| `Origin-Agent-Cluster: ?1` | Aísla cada origen en su propio proceso del navegador. |
| `X-DNS-Prefetch-Control: off` | No prefetcheo DNS de assets que linkeamos. |
| `X-Download-Options: noopen` | IE/Edge legacy: no abrir descargas en contexto del sitio. |
| `X-Permitted-Cross-Domain-Policies: none` | No respetar políticas Flash/PDF cross-domain. |
| `X-XSS-Protection: 0` | Apaga el filtro XSS legacy del navegador (ya no se usa, deprecated). |

`x-powered-by: Express` queda **deshabilitado** por defecto en Helmet — no leakeamos que el backend es Express.

### Por qué CSP está deshabilitado

CSP (`Content-Security-Policy`) es crítico para apps web que sirven HTML. Esta API **solo sirve JSON**, así que CSP es ruido y a veces rompe consumos legítimos. Si en el futuro se agregan rutas HTML (panel admin embebido, p.ej.), se reactiva con:

```js
app.use(helmet({
  contentSecurityPolicy: {
    directives: { defaultSrc: ["'self'"] },
  },
}));
```

## Cache control

Las rutas de la API no se cachean (decisión implícita por defecto — no setean `Cache-Control`). El cliente Flutter no cachea responses HTTP. Si en el futuro hace falta cachear lecturas, agregar middleware:

```js
app.use((req, res, next) => {
  if (req.method === 'GET' && req.path.startsWith('/api/products')) {
    res.set('Cache-Control', 'public, max-age=30');
  } else {
    res.set('Cache-Control', 'no-store');
  }
  next();
});
```

Importante: **nunca cachear endpoints autenticados sin `private`**, porque un proxy compartido podría servir la respuesta de un usuario a otro.

## Validación

```sh
# 1. CORS — origen accepted
curl -i -H "Origin: http://localhost:5173" http://localhost:3000/health
# Expect: Access-Control-Allow-Origin: *  (en dev; en prod sería el origen específico)

# 2. Headers de seguridad
curl -I http://localhost:3000/health
curl -k -I https://localhost:3443/health   # HSTS solo aparece visible en HTTPS

# 3. CORS preflight
curl -i -X OPTIONS http://localhost:3000/api/designs \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: authorization,content-type"
# Expect: 204 + Access-Control-Allow-*
```

### Calificación esperada

Pegando contra el backend desplegado en HTTPS:

- [securityheaders.com](https://securityheaders.com/) — esperamos **A** o **A+** con los headers de Helmet.
- [Mozilla Observatory](https://observatory.mozilla.org/) — similar.

(Estas herramientas requieren un dominio público; localhost no aplica.)
