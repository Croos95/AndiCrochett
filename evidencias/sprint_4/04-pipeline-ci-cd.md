# Sprint 4 · Pipeline CI/CD

El pipeline está definido en [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) y se dispara en cada `push` y `pull_request` contra `main`.

## Jobs

### `flutter-test` (Ubuntu latest, ~5–7 min)
1. **Checkout** del repo.
2. **Setup Flutter** vía `subosito/flutter-action@v2` (canal stable, con caché).
3. **`flutter pub get`** — resuelve dependencias.
4. **`flutter analyze --no-fatal-warnings --no-fatal-infos`** — análisis estático no bloqueante (`continue-on-error: true` mientras se estabilizan los lints heredados).
5. **`flutter test test/`** — corre las 39 pruebas (unitarias + integración). **Bloquea** el merge si fallan.
6. **`flutter build web`** — verifica que el bundle web compila. No bloqueante.

### `functions-lint` (Ubuntu latest, ~2 min)
Job paralelo para las Cloud Functions:
1. **Setup Node 20** con caché de `npm`.
2. **`npm ci`** dentro de `functions/`.
3. **`npm run lint --if-present`** — si existe el script, lo corre.

## Por qué dos jobs y no uno
- Permite que la suite Flutter falle/pase independientemente del lint de Node.
- Cachea dependencias por separado: el job de Functions no necesita la caché de pub.
- En PR, los dos jobs aparecen como checks separados, lo cual hace más fácil identificar qué área rompió.

## Configuración relevante de `ci.yml`
```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```
Cualquier rama puede abrir PR contra `main` y disparar el pipeline. Push directos a `main` también lo disparan (sirve como red de seguridad post-merge).

```yaml
timeout-minutes: 20
```
Corte duro para evitar jobs colgados consumiendo minutos de Actions.

## Lo que **no** corre el pipeline (todavía)
- **`integration_test/`** — requiere un device (Chrome headless o similar) y aún no está configurado en el job. Se ejecuta localmente con `flutter test integration_test/ -d chrome`.
- **Despliegue automático** — no hay job de `firebase deploy` aún; intencionalmente queda manual hasta cerrar Sprint 3 (seguridad).

## Cómo verificar que funciona después de subir
1. Push de la rama: `git push origin <rama>`.
2. Abre el PR en GitHub.
3. En la pestaña **Checks** debes ver `CI / Flutter analyze + test` y `CI / Cloud Functions (lint)`.
4. Click en cada uno para ver el log.

## Evidencia
- Workflow definition: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml).
- Captura de un run exitoso: [`capturas/`](capturas/) (se agrega tras el primer push).
