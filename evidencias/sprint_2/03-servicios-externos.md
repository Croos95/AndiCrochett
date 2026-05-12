# Sprint 2 · Integración de servicios externos

## Inventario de integraciones

| Servicio | Para qué | Configurado en |
|---|---|---|
| **Firebase Authentication** | Login email/password + Google Sign-In | `lib/features/auth/`, `firebase_options.dart` |
| **Cloud Firestore** | (Disponible, reglas listas) Catálogo público de productos | `firestore.rules`, `firestore.indexes.json` |
| **Cloud Functions** | API REST propia `/api/*` con CORS + JWT | `functions/` |
| **Firebase Hosting** | Sirve la web app + headers de seguridad | `firebase.json` |
| **api.frankfurter.app** | Tipos de cambio MXN → USD/EUR | `lib/core/services/exchange_rate_service.dart` |

## Diagrama (simplificado)

```
                          ┌──────────────────────────┐
                          │  AndiCrochett Flutter    │
                          │  (web / mobile / desktop)│
                          └────┬────────┬────────────┘
                               │        │
              firebase_auth ───┘        └──── http (Dart)
              firebase_core                   │
                  │                           │
                  │                           ├──► https://api.frankfurter.app
                  │                           │       (sin auth)
                  │                           │
                  │                           └──► https://<region>/api/secure/*
                  │                                   ▲
                  │   (ID token JWT)                  │
                  ▼                                   │
        ┌──────────────────────┐         ┌───────────┴────────────┐
        │  Firebase Auth       │ ───────►│  Cloud Functions       │
        │  (Google, email)     │  emite  │  Express + helmet +    │
        └──────────────────────┘  token  │  authenticate()        │
                                         └────────────────────────┘
                  ▼ futuro
        ┌──────────────────────┐
        │  Cloud Firestore     │
        │  catálogo público    │
        └──────────────────────┘
```

## Detalle: Firebase Auth
- Provider 1: email/password con verificación de correo (`hasVerifiedEmail`).
- Provider 2: Google Sign-In (vía `google_sign_in: ^7.2.0`).
- Persistencia de sesión: gestionada por Firebase SDK.
- Tokens: ID token JWT, expira 1h, refresh automático.

## Detalle: Cloud Functions
- Runtime Node 20.
- Express con helmet + CORS allowlist (ver [Sprint 3 · 03-cors-headers.md](../sprint_3/03-cors-headers.md)).
- Rutas:
  - `GET /api/health` — pública, healthcheck.
  - `GET /api/secure/me` — autenticada, devuelve el usuario.
  - `GET /api/secure/ping` — autenticada, healthcheck con uid.
- Variables de entorno: `ALLOWED_ORIGINS` (CSV de orígenes).

## Detalle: frankfurter.app
- Sin API key.
- Sin SLA formal (pero es del BCE, confiable).
- Política: si falla, el dashboard sigue funcionando, solo no muestra la conversión.

## Trabajos pendientes (no en este sprint)
- **Firestore sync de productos** — la app es offline-first con SQLite; sincronizar al catálogo público de Firestore sería un Sprint 6.
- **Push notifications** vía FCM para avisar pedidos nuevos.
- **Cloud Storage** para imágenes de productos (hoy son URLs externas).

## Tabla de decisiones

| Pregunta | Decisión | Por qué |
|---|---|---|
| ¿REST propia o GraphQL? | REST | Cloud Functions/Express es trivial; GraphQL agrega complejidad sin payoff |
| ¿Pegar a Firestore desde Flutter directo o vía REST? | Por ahora: Auth directo, datos vía SQLite local. REST cuando se sincronice | Offline-first con SQLite es más rápido y barato |
| ¿API key del exchange rate? | frankfurter (sin key) | Cero gestión de secretos para un PoC |
| ¿Otra API externa además de frankfurter? | Por ahora no | Una basta para demostrar el patrón; agregar otra es trivial repitiendo el template |
