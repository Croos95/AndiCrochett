# Sprint 4 · Pruebas de integración

Tras la migración del Sprint 4 inicial, las pruebas de integración cambiaron de objetivo: antes verificaban el `DatabaseHelper` local contra SQLite vía FFI; ahora verifican el **backend Node + SQLite centralizado** contra rutas HTTP reales con [`supertest`](https://www.npmjs.com/package/supertest).

Esto es más fiel a la realidad — el cliente Flutter habla HTTP, no SQL — y se ejecuta en CI sin tooling de FFI.

## Por qué backend real y no mocks

Un mock acepta cualquier request que le pasemos; supertest pega contra el `Express app` real, lo cual valida:
- El middleware de auth (rechazo de requests sin token).
- Las rutas montadas correctamente bajo `/api`.
- El esquema SQLite (foreign keys, NOT NULL, índices).
- Las transacciones de pedidos (descuento + devolución de stock atómicos).
- La normalización de inputs (`cliente_id=0` → null).
- El handling de errores (FK violations → 400 con mensaje claro).

Mockear escondería bugs que solo aparecen con el motor real.

## Cobertura

[`backend/test/smoke.test.js`](../../backend/test/smoke.test.js): **12 tests** divididos en bloques temáticos.

### Health y auth
| Test | Verifica |
|---|---|
| `GET /health responde 200 con ok=true` | Liveness sin auth |
| `GET /api/designs sin auth → 401` | Middleware bloquea requests sin token |
| `GET /api/designs con token de prueba → 200 (lista vacía)` | Bypass de auth en `NODE_ENV=test` con tokens `test-<uid>` |
| `GET ruta inexistente → 404` | Handler 404 final |

### Designs (CRUD)
| Test | Verifica |
|---|---|
| `POST /api/designs crea y luego GET lo devuelve` | INSERT + SELECT roundtrip, `usuario_id` se inyecta desde el token |
| `POST /api/designs sin "nombre" → 400` | Validación de body |

### Orders (transacciones + validación de FK)
| Test | Verifica |
|---|---|
| `POST /api/orders con cliente_id=0 y sin items → 201` | Normaliza `cliente_id=0` a `null` para no violar FK |
| `POST /api/orders con producto_id inexistente → 400` | Pre-valida FK de items_pedido y devuelve mensaje claro |

### Security y audit_log
| Test | Verifica |
|---|---|
| `POST /api/security/login-attempt es público y registra` | Endpoint accesible sin token, persiste éxito y fallo |
| `GET /api/analytics/security agrega login_attempts y api_calls` | Queries de agregación sobre `audit_log` (cuenta, suma, group by, top endpoints) |
| `GET /api/analytics/dashboard incluye productsNeedingRestock` | Endpoint extendido del dashboard de negocio |

## Aislamiento entre tests

```js
// backend/test/smoke.test.js
process.env.NODE_ENV = 'test';
process.env.DB_PATH = path.join(os.tmpdir(), `andicrochett-test-${Date.now()}.db`);

const { createApp } = require('../src/app');
const app = createApp();

after(() => {
  for (const ext of ['', '-journal', '-wal', '-shm']) {
    try { fs.unlinkSync(tmpDb + ext); } catch (_) {}
  }
});
```

Cada corrida usa un archivo SQLite **temporal** distinto (`/tmp/andicrochett-test-<timestamp>.db`), creado al import del app y borrado en el `after()` global. No toca `backend/data/andicrochett.db` (la BD de desarrollo).

## Bypass de auth en tests

[`backend/src/auth.js`](../../backend/src/auth.js) detecta `NODE_ENV=test` y acepta tokens con prefijo `test-`:

```js
if (process.env.NODE_ENV === 'test' && match[1].startsWith('test-')) {
  req.user = {
    uid: match[1].slice('test-'.length) || 'test-user',
    email: 'test@example.com',
    emailVerified: true,
  };
  return next();
}
```

Esto evita pedir credenciales reales de Firebase en CI y mantiene el `verifyFirebaseToken` real en producción. El test pasa `Authorization: Bearer test-user-1` y el backend lo decodifica como `uid='user-1'`.

## Cómo ejecutarlas

```sh
cd backend
npm test
```

Salida esperada (ejecución actual del sprint):
```
✔ GET /health responde 200 con ok=true (40ms)
✔ GET /api/designs sin auth → 401 (10ms)
✔ GET /api/designs con token de prueba → 200 (lista vacía) (9ms)
✔ POST /api/designs crea y luego GET lo devuelve (32ms)
✔ POST /api/designs sin "nombre" → 400 (5ms)
✔ GET /api/analytics/dashboard refleja los inserts (6ms)
✔ GET ruta inexistente → 404 (5ms)
✔ POST /api/orders con cliente_id=0 y sin items → 201 (8ms)
✔ POST /api/orders con producto_id inexistente → 400 (6ms)
✔ POST /api/security/login-attempt es público y registra (11ms)
✔ GET /api/analytics/security agrega login_attempts y api_calls (15ms)
✔ GET /api/analytics/dashboard incluye productsNeedingRestock (11ms)
ℹ tests 12  pass 12  fail 0  duration_ms 651
```

## Notas

- `supertest` se invoca con `request(app)` — **no abre un puerto**, llama directo a la app Express. Por eso varios tests pueden correr en paralelo sin conflicto de puertos.
- En CI corren en Ubuntu sin problema: `better-sqlite3` tiene prebuilt binaries para Linux + Node 20.
- Si quieres correr solo un test específico: `node --test --test-name-pattern="login-attempt" backend/test/smoke.test.js`.
