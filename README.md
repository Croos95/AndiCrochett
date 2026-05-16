# AndiCrochett

> Plataforma fullstack para una microempresa de crochet: catálogo público + panel administrativo con gestión de inventario, agenda de pedidos, diseños y patrones.

App **Flutter multiplataforma** (web · Android · iOS · Windows) que consume un **backend REST propio** en Node.js + SQLite. Mantiene Firebase Auth para identidad y Firebase Analytics para telemetría de uso. Incluye un dashboard de analítica con dos dimensiones (Negocio + Ciberseguridad) alimentado por el `audit_log` del backend.

---

## Sprints y evidencias

Las entregas formales viven en [`evidencias/`](evidencias/), separadas por sprint. Cada carpeta contiene un `README.md` con la descripción del sprint + documentación específica + ubicación de capturas/GIFs.

| Sprint | Tema | Evidencias |
|---|---|---|
| 1 | UX/UI — prototipo + leyes UX | [`evidencias/sprint_1/`](evidencias/sprint_1/) |
| 2 | Conexiones / Flutter — SQLite + REST + JSON + servicios externos | [`evidencias/sprint_2/`](evidencias/sprint_2/) |
| 3 | Seguridad — JWT + CORS + HTTPS local + Helmet | [`evidencias/sprint_3/`](evidencias/sprint_3/) |
| 4 | Pruebas — unit + integración + E2E + CI/CD | [`evidencias/sprint_4/`](evidencias/sprint_4/) |
| 5 | Analítica — eventos + dashboard dual + análisis | [`evidencias/sprint_5/`](evidencias/sprint_5/) |

---

## Stack

### Cliente (Flutter)
- **Flutter** 3.9+ con Material 3 + Material You-style.
- **`go_router`** — navegación + redirects basados en auth + `FirebaseAnalyticsObserver` para screen tracking.
- **`provider`** — state management (`AuthProvider`, `InventoryProvider`).
- **`http`** — capa HTTP, encapsulada en `ApiClient` con `tokenProvider` inyectable.
- **`firebase_core` + `firebase_auth` + `firebase_analytics`** — identidad y telemetría.
- **`google_sign_in`** — login con Google.
- **Tipografía Lora** + paleta verde oliva.

### Backend (Node.js propio en `backend/`)
- **Express** + **Helmet** (10 headers de seguridad) + **CORS** configurable.
- **`better-sqlite3`** — SQLite síncrono, con WAL y FK enforcement.
- **`firebase-admin`** — verifica Firebase ID tokens (JWT).
- **`selfsigned`** + **`cross-env`** — HTTPS local opt-in con cert auto-firmado.
- **`node:test` + `supertest`** — suite de pruebas.

### Integraciones externas
- **frankfurter.app** — tipos de cambio MXN → USD/EUR sin API key (visible en el dashboard).
- **Firebase Authentication** — emisión y rotación de JWT.
- **Firebase Analytics** — telemetría de eventos de uso.

---

## Arquitectura

```
┌─────────────────┐        Bearer JWT (Firebase)        ┌─────────────────────┐
│  Flutter app    │  ──────────────────────────────▶    │  Backend Node/Express│
│  (web/Android)  │                                      │     :3000 / :3443    │
└─────────────────┘  ◀──────────────────────────────    └──────────┬──────────┘
        │                  JSON                                    │
        │                                                          │
        ▼                                                          ▼
┌─────────────────┐                                        ┌──────────────┐
│ Firebase Auth   │                                        │   SQLite     │
│ Firebase        │                                        │ (centralizada│
│ Analytics       │                                        │  con WAL)    │
└─────────────────┘                                        └──────────────┘
                                                                   │
                                                                   ▼
                                                            ┌──────────────┐
                                                            │  audit_log   │
                                                            │  (seguridad) │
                                                            └──────────────┘
```

---

## Estructura del repositorio

```
.
├── lib/                              # Cliente Flutter
│   ├── core/
│   │   ├── config/
│   │   │   ├── env.dart              # autodetecta plataforma (10.0.2.2 / localhost / https)
│   │   │   └── routes.dart           # go_router + FirebaseAnalyticsObserver
│   │   ├── services/
│   │   │   ├── api_client.dart       # HTTP client con tokenProvider
│   │   │   ├── analytics_service.dart # Data layer + Console/Firebase/InMemory sinks
│   │   │   ├── auth_service.dart     # perfil derivado de Firebase Auth
│   │   │   ├── security_reporter.dart # reporta login attempts al backend
│   │   │   └── exchange_rate_service.dart  # API externa
│   │   └── widgets/                  # AppButton, AppInput, etc.
│   ├── features/
│   │   ├── auth/                     # login, registro, Google Sign-In
│   │   ├── inventory/                # productos, stock, ajustes
│   │   ├── agenda/                   # pedidos, calendario
│   │   ├── designs/                  # diseños de crochet
│   │   ├── patterns/                 # patrones con parser propio
│   │   ├── clients/                  # clientes
│   │   ├── analytics/                # dashboard (Negocio + Seguridad)
│   │   ├── dashboard/                # entrada principal post-login
│   │   └── landing/, landing_connection/  # catálogo público
│   └── main.dart                     # bootstrap + analytics observer
│
├── backend/                          # Backend Node propio
│   ├── src/
│   │   ├── server.js                 # arranca HTTP + (opcional) HTTPS
│   │   ├── app.js                    # Express + Helmet + CORS + audit
│   │   ├── db.js                     # SQLite schema con WAL + FK
│   │   ├── auth.js                   # verifyFirebaseToken (bypass test)
│   │   ├── https.js                  # cert auto-firmado para dev
│   │   ├── middleware/audit.js       # persiste cada request en audit_log
│   │   └── routes/                   # designs, patterns, products, clients,
│   │                                 # orders, catalog, analytics, security
│   ├── test/smoke.test.js            # 12 tests con supertest
│   └── data/andicrochett.db          # SQLite centralizado (gitignored)
│
├── test/                             # Pruebas Flutter
│   ├── unit/                         # modelos, parser, servicios
│   └── e2e/                          # E2E lógico (MockClient) - corre en CI
│
├── integration_test/                 # E2E binding-real (requiere device)
│
├── android/                          # config nativa Android
│   └── app/src/main/res/xml/
│       └── network_security_config.xml  # cleartext solo para dev hosts
│
├── .github/workflows/ci.yml          # 5 jobs en paralelo
│
├── evidencias/                       # Documentación por sprint
│   ├── sprint_1/  ... sprint_5/
│
└── documentation/                    # Documentos técnicos legacy (PDFs, fixes)
```

---

## Requisitos

- **Flutter SDK 3.9+** (Dart 3.9+)
- **Node 20+**
- Una cuenta Firebase con proyecto configurado vía `flutterfire configure`
- Archivo `firebase-service-account.json` para el backend (Firebase Console → Project Settings → Service accounts → Generate new private key). Va en `backend/firebase-service-account.json` (gitignored).

---

## Configuración rápida

```sh
# 1. Dependencias Flutter
flutter pub get

# 2. Dependencias del backend
cd backend && npm install && cd ..

# 3. (Opcional) regenerar credenciales Firebase
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## Ejecución

Necesitas **dos terminales** corriendo en paralelo: backend + Flutter.

### Terminal 1 — Backend

```sh
cd backend
npm run dev                 # HTTP en :3000 con autoreload (--watch)
# o
npm run dev:https           # HTTP en :3000 + HTTPS en :3443 (cert auto-firmado)
```

### Terminal 2 — Flutter

```sh
flutter run                 # autodetecta plataforma y URL
# - Web/iOS/Desktop → http://localhost:3000/api
# - Android emulator → http://10.0.2.2:3000/api
```

Para dispositivo Android físico (LAN), inyectar la IP del PC:
```sh
flutter run --dart-define=BASE_URL=http://192.168.X.X:3000/api
```

En producción, exigir HTTPS:
```sh
flutter build appbundle --release \
  --dart-define=BASE_URL=https://tu-backend.com/api
```

---

## Pruebas

```sh
# Suite Flutter completa (unit + e2e lógico)
flutter test

# Solo unitarias
flutter test test/unit/

# Solo E2E del dashboard (sin device)
flutter test test/e2e/

# E2E binding-real (requiere device)
flutter test integration_test/ -d <device>

# Backend (smoke + integración con SQLite temporal)
cd backend && npm test
```

**Conteo orientativo:** 60 tests Flutter + 2 E2E + 3 widget E2E + 12 backend = **~77 pruebas automatizadas**.

Detalles por categoría en [`evidencias/sprint_4/`](evidencias/sprint_4/).

---

## CI/CD

Pipeline en [`.github/workflows/ci.yml`](.github/workflows/ci.yml) — corre en cada push y PR a `main`. **5 jobs**, varios en paralelo:

| Job | Qué hace |
|---|---|
| `analizar_y_probar_flutter` | format + analyze + `flutter test --coverage` |
| `probar_backend` | `npm ci` + `npm test` en `backend/` |
| `compilar_android` | `flutter build appbundle --release` (depende de los tests) |
| `compilar_web` | `flutter build web` (depende de los tests) |
| `ci_functions` | CI legado de Cloud Functions (mientras coexistan) |

Detalles en [`evidencias/sprint_4/04-pipeline-ci-cd.md`](evidencias/sprint_4/04-pipeline-ci-cd.md).

---

## Seguridad

- **JWT (Firebase ID tokens)** — todas las rutas del backend (excepto `/health` y `POST /api/security/login-attempt`) exigen `Authorization: Bearer <token>`. El `usuario_id` se inyecta desde el token verificado, nunca desde el body.
- **HTTPS local** — `npm run dev:https` levanta TLS en `:3443` con cert auto-firmado (`selfsigned`); cache en `backend/certs/`. En producción, `Env.baseUrl` exige `https://` y el build falla si no se cumple.
- **CORS + Helmet** — CORS configurable por env, Helmet aplica 10 headers (`Strict-Transport-Security`, `X-Frame-Options`, `Referrer-Policy`, `X-Content-Type-Options`, etc.).
- **NetworkSecurityConfig (Android)** — cleartext (HTTP) permitido **solo** para `localhost`, `127.0.0.1`, `10.0.2.2`. Cualquier host de producción debe ser HTTPS.
- **Audit log** — cada request HTTP + cada intento de login se persiste en la tabla `audit_log` del backend. Alimenta la pestaña Seguridad del dashboard interno (intentos fallidos, top endpoints, errores 5xx).

Documentación detallada en [`evidencias/sprint_3/`](evidencias/sprint_3/).

---

## Analítica

Dos canales complementarios:

| Canal | Para qué | Dónde se ve |
|---|---|---|
| **Firebase Analytics** | Eventos de uso del usuario final (login, screen view, producto creado). Datos agregados. | Firebase Console → Analytics |
| **`audit_log` (SQLite del backend)** | Métricas operativas y de seguridad del backend (cada request, cada intento de login). Datos granulares. | Dashboard interno → tab "Seguridad" |

El dashboard interno (`/analytics`) tiene **dos pestañas**:
- **Negocio** — 6 KPIs + conversión de divisas (frankfurter.app) + pedidos por estado + top productos vendidos + productos por reabastecer.
- **Seguridad** — intentos de login (7d) + llamadas a la API (24h) + endpoints más usados + logins fallidos recientes con IP y código de error.

Documentación + análisis de cada métrica en [`evidencias/sprint_5/`](evidencias/sprint_5/).

---

## Documentación adicional

Los documentos técnicos heredados viven en [`documentation/`](documentation/):

- [`Sprint-1 AndiCrochett.pdf`](documentation/Sprint-1%20AndiCrochett.pdf) — entregable original del Sprint 1.
- [`Requisitos patrones.docx`](documentation/Requisitos%20patrones.docx) — especificación del feature de patrones.
- [`SQLITE_IMPLEMENTATION.md`](documentation/SQLITE_IMPLEMENTATION.md) — notas históricas de la implementación SQLite local (antes de centralizar al backend).
- [`FIREBASE_EMAIL_CONFIG.md`](documentation/FIREBASE_EMAIL_CONFIG.md) — configuración de envío de correos de Firebase.
- [`EMAIL_VERIFICATION_FIXES.md`](documentation/EMAIL_VERIFICATION_FIXES.md) — historial de fixes del flujo de verificación de email.
- [`VERIFY_EMAIL_CHECKLIST.md`](documentation/VERIFY_EMAIL_CHECKLIST.md) — checklist de prueba para verificación de email.

Para el backend, ver [`backend/README.md`](backend/README.md) — incluye setup, deploy a Railway/Render y configuración del service account de Firebase.

---

## Licencia

Proyecto académico — Taller de Full Stack.
