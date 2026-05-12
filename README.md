# AndiCrochett

> Plataforma fullstack para una microempresa de crochet: catálogo público + panel administrativo con gestión de inventario, agenda de pedidos, diseños y patrones.

App Flutter multiplataforma (web · Android · iOS · Windows) conectada a Firebase para auth + Cloud Functions y a SQLite para persistencia local offline-first. Incluye dashboard de analítica con consumo de API REST externa.

---

## Sprints y evidencias

Las entregas formales viven en [`evidencias/`](evidencias/), separadas por sprint. Cada carpeta contiene un `README.md` con la descripción del sprint + documentación específica + ubicación de capturas/GIFs.

| Sprint | Tema | Evidencias |
|---|---|---|
| 1 | UX/UI — prototipo + leyes UX | [`evidencias/sprint_1/`](evidencias/sprint_1/) |
| 2 | Conexiones / Flutter — SQLite + REST + JSON + servicios externos | [`evidencias/sprint_2/`](evidencias/sprint_2/) |
| 3 | Seguridad — JWT + CORS + HTTPS + headers | [`evidencias/sprint_3/`](evidencias/sprint_3/) |
| 4 | Pruebas — unit + integración + E2E + CI/CD | [`evidencias/sprint_4/`](evidencias/sprint_4/) |
| 5 | Analítica — eventos + dashboard + análisis | [`evidencias/sprint_5/`](evidencias/sprint_5/) |

App desplegada: **[https://andicrochett-bcb21.web.app/](https://andicrochett-bcb21.web.app/)**

---

## Stack

### Frontend
- **Flutter** 3.9+ con Material 3.
- **`go_router`** para navegación + redirects basados en auth.
- **`provider`** para state management.
- **`sqflite`** para persistencia local.
- **Tipografía Lora** + paleta verde oliva.

### Backend
- **Cloud Functions** Node 20, Express, Helmet, CORS allowlist.
- **Firebase Auth** (email/password + Google Sign-In).
- **Firebase Hosting** con headers de seguridad (HSTS, CSP, X-Frame-Options, etc.).
- **Firestore** (provisionado, reglas listas).

### Integraciones externas
- **frankfurter.app** — tipos de cambio MXN → USD/EUR sin API key.

---

## Estructura del repositorio

```
.
├── lib/                          # Código Flutter
│   ├── core/                     # Servicios, config, widgets compartidos
│   │   ├── services/
│   │   │   ├── analytics_service.dart    (Sprint 5)
│   │   │   ├── exchange_rate_service.dart (Sprint 2)
│   │   │   └── secure_api_client.dart    (Sprint 3)
│   │   └── ...
│   ├── features/                 # Features por dominio
│   │   ├── auth/
│   │   ├── inventory/
│   │   ├── agenda/
│   │   ├── designs/
│   │   ├── patterns/
│   │   ├── analytics/            (Sprint 5)
│   │   └── ...
│   └── database_helper.dart      # Singleton SQLite con 9 migraciones
│
├── functions/                    # Cloud Functions (API REST + JWT)
│   ├── index.js
│   ├── middleware/auth.js
│   └── test/auth.test.js
│
├── test/                         # Pruebas Flutter (Sprint 4)
│   ├── unit/                     # Unitarias (modelos, parser, servicios)
│   └── integration/              # SQLite real (FFI)
│
├── integration_test/             # Pruebas E2E (binding real)
│
├── .github/workflows/ci.yml      # Pipeline CI (Sprint 4)
│
├── evidencias/                   # Documentación por sprint
│   ├── sprint_1/
│   ├── sprint_2/
│   ├── sprint_3/
│   ├── sprint_4/
│   └── sprint_5/
│
└── documentation/                # Documentos técnicos legacy
```

---

## Requisitos

- Flutter SDK 3.9+ (Dart 3.9+)
- Firebase CLI
- Node 20 (para `functions/`)
- Una cuenta Firebase con proyecto configurado vía `flutterfire configure`

---

## Configuración rápida

```sh
# 1. Dependencias Flutter
flutter pub get

# 2. Dependencias del backend
cd functions && npm install && cd ..

# 3. (Opcional) regenerar credenciales Firebase
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## Ejecución

### App web (desarrollo)
```sh
flutter run -d chrome --web-hostname localhost --web-port 5000
```

### App Android
```sh
flutter run -d android
```

### Backend localmente (emulador)
```sh
firebase emulators:start --only functions,hosting
```

### Build de producción + deploy
```sh
flutter build web
firebase deploy --only functions,hosting
```

---

## Pruebas

```sh
# Suite Flutter (unidad + integración) — serial obligatorio
flutter test test/ -j 1

# Pruebas E2E (necesita device)
flutter test integration_test/ -d chrome

# Pruebas del backend (middleware JWT)
cd functions && npm test
```

Total: **62 tests Flutter + 5 tests Node = 67 pruebas automatizadas**. Detalles en [`evidencias/sprint_4/`](evidencias/sprint_4/).

---

## CI/CD

Pipeline en [`.github/workflows/ci.yml`](.github/workflows/ci.yml) — corre en cada push y PR a `main`:
- `flutter-test`: analyze + tests + build web.
- `functions-lint`: install + lint + tests.

---

## Seguridad

- **HTTPS forzado**: HSTS de 1 año en Firebase Hosting, redirect desde HTTP en `web/index.html`, `Env.baseUrl` exige `https://` en producción.
- **CORS allowlist**: lista blanca explícita, sin wildcards, configurable vía `ALLOWED_ORIGINS`.
- **Headers de seguridad**: 6 headers aplicados por Hosting (CSP, X-Frame-Options, Permissions-Policy, etc.). Helmet en Functions.
- **JWT**: rutas `/api/secure/*` exigen Firebase ID token válido. Tokens rotados por Firebase, expiración 1h.

Documentación detallada en [`evidencias/sprint_3/`](evidencias/sprint_3/).

---

## Documentación adicional

Los documentos técnicos heredados (verificación de email, configuración Firebase, implementación de SQLite) viven en [`documentation/`](documentation/).

- [`documentation/Sprint-1 AndiCrochett.pdf`](documentation/Sprint-1%20AndiCrochett.pdf) — entregable original del Sprint 1.
- [`documentation/Requisitos patrones.docx`](documentation/Requisitos%20patrones.docx) — especificación del feature de patrones.
- [`documentation/SQLITE_IMPLEMENTATION.md`](documentation/SQLITE_IMPLEMENTATION.md) — notas de implementación de SQLite.
- [`documentation/FIREBASE_EMAIL_CONFIG.md`](documentation/FIREBASE_EMAIL_CONFIG.md) — configuración de envío de correos.
- [`documentation/EMAIL_VERIFICATION_FIXES.md`](documentation/EMAIL_VERIFICATION_FIXES.md) — historial de fixes del flujo de verificación.
- [`documentation/VERIFY_EMAIL_CHECKLIST.md`](documentation/VERIFY_EMAIL_CHECKLIST.md) — checklist de prueba para verificación de email.

---

## Licencia

Proyecto académico — Taller de Full Stack.

Prueba pipeline