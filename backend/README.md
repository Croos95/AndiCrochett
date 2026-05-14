# AndiCrochett Backend

API REST en Node.js + Express con SQLite centralizado. Sirve como fuente única de datos para la app Flutter de AndiCrochett.

## Stack

- **Node.js 20+**
- **Express** — framework HTTP
- **better-sqlite3** — driver SQLite síncrono (rápido, simple)
- **firebase-admin** — verifica tokens de Firebase Auth del cliente

## Estructura

```
backend/
├── package.json
├── .env.example          # copia a .env y edita
├── .gitignore
├── data/                 # aquí vive andicrochett.db (creado automáticamente)
├── firebase-service-account.json   # NO commitear (ver setup)
└── src/
    ├── server.js         # arranque Express
    ├── db.js             # instancia SQLite + esquema (CREATE TABLE IF NOT EXISTS)
    ├── auth.js           # middleware verifyFirebaseToken
    └── routes/
        └── patterns.js   # CRUD de patrones (ejemplo completo)
```

## Setup local

```bash
cd backend
npm install
cp .env.example .env
```

### Obtener las credenciales de Firebase Admin

1. Ve a Firebase Console → tu proyecto → ⚙️ Configuración → "Cuentas de servicio".
2. Click en "Generar nueva clave privada". Descarga el JSON.
3. Guárdalo como `backend/firebase-service-account.json` (está en `.gitignore`).

### Arrancar

```bash
npm run dev          # HTTP en :3000 con --watch (recarga al cambiar archivos)
npm run dev:https    # HTTP en :3000 + HTTPS en :3443 (TLS auto-firmado)
npm start            # producción (HTTP en :3000; HTTPS si HTTPS_PORT está seteado)
```

El servidor escucha en `http://localhost:3000`. La base de datos se crea en `data/andicrochett.db` la primera vez.

### HTTPS local

Con `npm run dev:https` el server levanta **además** HTTPS en el puerto 3443. La primera ejecución genera un certificado auto-firmado en `backend/certs/` (cubre `localhost`, `127.0.0.1` y `10.0.2.2` para el emulador Android) y lo cachea para futuras corridas.

Cosas a saber:
- El cert NO está confiado por defecto. Espera `NET::ERR_CERT_AUTHORITY_INVALID` en Chrome — acepta la advertencia para probar. En `curl` usa `--insecure` (`-k`).
- Las cabeceras de seguridad (HSTS, X-Frame-Options, etc.) las inyecta **`helmet`** y aplican igual sobre HTTP y HTTPS. El header `Strict-Transport-Security` solo tiene efecto real sobre HTTPS.
- Para forzar HTTPS desde el cliente Flutter en producción, ya hay validación en [`Env.baseUrl`](../lib/core/config/env.dart) que exige `https://` cuando `dart.vm.product` está activo.

Prueba rápida:

```bash
curl -k https://localhost:3443/health
# {"ok":true,"service":"andicrochett-backend"}

curl -k -I https://localhost:3443/health | grep -i strict
# Strict-Transport-Security: max-age=31536000; includeSubDomains
```

Si quieres que el cert sea confiado en tu máquina (sin warnings de navegador), usa [`mkcert`](https://github.com/FiloSottile/mkcert): instala su CA local, genera certs con `mkcert localhost 127.0.0.1 10.0.2.2`, y copia los archivos a `backend/certs/` (`localhost.crt` y `localhost.key`).

## Probar la API

Las rutas de datos viven bajo `/api`. Health queda en la raíz.

```bash
# Health check (sin auth)
curl http://localhost:3000/health

# Listar patrones
curl http://localhost:3000/api/patterns \
  -H "Authorization: Bearer <FIREBASE_ID_TOKEN>"

# Crear patrón
curl -X POST http://localhost:3000/api/patterns \
  -H "Authorization: Bearer <FIREBASE_ID_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Mi patrón","tipo":"rows","design_id":1}'
```

Para obtener un `FIREBASE_ID_TOKEN` durante desarrollo, desde la app Flutter:

```dart
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
print(token);
```

## Endpoints implementados

Todas las rutas (excepto `/health`) requieren `Authorization: Bearer <FIREBASE_ID_TOKEN>`.

### Health
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/health` | Health check (público) |

### Patterns (compartido)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/patterns` | Lista todos. Filtro opcional `?designId=N` |
| GET | `/patterns/:id` | Detalle |
| POST | `/patterns` | Crea (registra `usuario_id` de quien lo creó) |
| PUT | `/patterns/:id` | Actualiza (parcial) |
| DELETE | `/patterns/:id` | Elimina |

### Designs (compartido entre usuarios)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/designs` | Lista todos |
| GET | `/designs/:id` | Detalle |
| POST | `/designs` | Crea (registra `usuario_id` de quien lo creó) |
| PUT | `/designs/:id` | Actualiza (parcial) |
| DELETE | `/designs/:id` | Elimina (CASCADE borra patrones del diseño) |

### Products / Inventario (compartido)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/products` | Lista todos. Soporta `?q=...` (búsqueda) y `?categoria=...` |
| GET | `/products/:id` | Detalle |
| POST | `/products` | Crea (estado se calcula del stock si no se manda) |
| PUT | `/products/:id` | Actualiza (parcial) |
| PATCH | `/products/:id/stock` | Setea cantidad absoluta y recalcula estado |
| POST | `/products/:id/adjust-stock` | Body `{delta: n}` — incrementa/decrementa |
| DELETE | `/products/:id` | Elimina |

### Clients (compartido)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/clients` | Lista todos |
| GET | `/clients/:id` | Detalle |
| POST | `/clients` | Crea |
| PUT | `/clients/:id` | Actualiza (parcial) |
| DELETE | `/clients/:id` | Elimina |

### Orders / Pedidos (compartido) — usa transacciones
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/orders` | Lista todos con items embebidos |
| GET | `/orders/:id` | Detalle con items |
| POST | `/orders` | Crea pedido + items + descuenta stock (transacción) |
| PUT | `/orders/:id` | Actualiza pedido. Si manda `items`, los reemplaza |
| PATCH | `/orders/:id/status` | Cambia solo el estado |
| POST | `/orders/:id/cancel` | Cancela: devuelve stock + borra items + borra pedido (transacción) |
| DELETE | `/orders/:id` | Elimina (CASCADE borra items, sin devolver stock) |

### Catalog Settings (por usuario)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/catalog/me` | Settings del usuario autenticado (devuelve `null` si no existe) |
| GET | `/catalog/:userId` | Settings de un usuario específico |
| PUT | `/catalog/me` | UPSERT: crea o actualiza (parcial) |

**Pendiente**:

- `/users` — sincronización del perfil de usuario (la app crea el registro en Firebase, podríamos espejarlo aquí para `display_name`, `photo_url`, `settings`).
- Endpoint público de catálogo (sin auth) para landing pages.

## Seguridad

- Toda ruta bajo `/patterns` (y futuras) usa `verifyFirebaseToken`.
- El `usuario_id` se toma del token (`req.user.uid`), **nunca del body** del cliente. Esto evita que un usuario manipule el ID y acceda a datos de otros.
- Todas las queries incluyen `WHERE usuario_id = ?` para aislar datos por usuario.

## Deploy

### Railway (recomendado)

1. Conecta el repo en https://railway.app.
2. Configura "Root Directory" = `backend`.
3. Agrega un volumen persistente montado en `/app/data`.
4. Variables de entorno:
   - `PORT` (lo asigna Railway, no lo pongas manual)
   - `DB_PATH=/app/data/andicrochett.db`
   - `FIREBASE_SERVICE_ACCOUNT_PATH=/app/firebase-service-account.json`
   - `CORS_ORIGIN=*` (o el dominio de tu app)
5. Sube el `firebase-service-account.json` como secret file en `/app/firebase-service-account.json`.

### Render

Similar a Railway pero con "Persistent Disk" montado en `/app/backend/data`.

## Operación

- **Backup**: copia `data/andicrochett.db` periódicamente (cron sencillo).
- **Modo WAL**: ya está activado (`PRAGMA journal_mode=WAL`) — mejora la concurrencia de lecturas.
- **Logs**: van a stdout, los captura el host (Railway/Render).
