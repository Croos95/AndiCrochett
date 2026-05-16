# Sprint 4 · Pipeline CI/CD

El pipeline está definido en [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) y se dispara en cada `push` y `pull_request` contra `main`.

## Jobs (5 en total, varios en paralelo)

### 1. `analizar_y_probar_flutter` (Ubuntu, ~5–7 min)
1. **Checkout** del repo.
2. **Setup Java JDK 17** (necesario para `flutter build appbundle`).
3. **Setup Flutter** vía `subosito/flutter-action@v2` (canal stable, con caché).
4. **Cache de `~/.pub-cache`** keyeado por hash de `pubspec.lock`.
5. **`flutter pub get`**.
6. **`dart format --output=none --set-exit-if-changed .`** — falla si hay archivos sin formatear.
7. **`flutter analyze`** — análisis estático estricto.
8. **`flutter test --coverage`** — corre todas las pruebas y genera `coverage/lcov.info`.
9. **Sube cobertura** como artefacto.

### 2. `probar_backend` (Ubuntu, ~2 min) — **paralelo al de Flutter**
1. Checkout + setup Node 20.
2. Cache de `~/.npm` keyeado por `backend/package-lock.json`.
3. `npm ci` dentro de `backend/`.
4. `npm test` con `NODE_ENV=test`.

### 3. `compilar_android` (Ubuntu, ~10 min) — **depende del job 1**
1. Setup Java + Flutter + pub cache.
2. `flutter build appbundle --release` → genera `app-release.aab`.
3. Sube el AAB como artefacto.

### 4. `compilar_web` (Ubuntu, ~5 min) — **depende del job 1**
1. Setup Flutter + pub cache.
2. `flutter build web`.
3. Sube el bundle web como artefacto.

### 5. `ci_functions` (Ubuntu, ~2 min) — **paralelo**
Job heredado del backend anterior (Cloud Functions). Sigue en el pipeline mientras `functions/` esté en el repo. Setup Node + `npm ci` + lint + test bajo `functions/`.

## Por qué este diseño

- **Backend y Flutter analizan en paralelo** — feedback más rápido. Si solo cambiaste un endpoint, no esperas el build de Android.
- **Builds Android y Web dependen del job 1** — si los tests fallan, no se desperdician minutos compilando.
- **Cache separada de pub y npm** — cada job sólo carga lo suyo.
- **Cobertura como artefacto** — descargable desde el run de GitHub Actions para revisar coverage del PR.
- **`-j 1` ya no es necesario** — los tests viejos compartían un archivo SQLite global (`andicrochett.db` en cwd). Ahora cada test del backend usa su propio archivo temporal en `/tmp`, y los tests de Flutter ya no tocan SQLite local.

## Configuración relevante

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```
Cualquier rama puede abrir PR contra `main` y disparar el pipeline. Push directos a `main` también lo disparan (red de seguridad post-merge).

```yaml
timeout-minutes: 20
```
Corte duro para evitar jobs colgados consumiendo minutos de Actions.

## Lo que **no** corre el pipeline (todavía)

- **`integration_test/`** (widget tests sobre device) — requiere un emulador Android en el runner, lo cual añade ~5 min al pipeline. Sí se corren en `test/e2e/` los E2E lógicos.
- **Despliegue automático** — `firebase deploy` queda manual hasta confirmar que se vaya a usar el nuevo backend Node (el job `ci_functions` se mantiene mientras coexisten ambos).

## Cómo verificar que funciona después de subir

1. `git push origin <rama>`.
2. Abre el PR en GitHub.
3. En la pestaña **Checks** debes ver las cinco entradas:
   - `CI / Flutter — Analizar y probar`
   - `CI / Backend — Tests (Node + SQLite)`
   - `CI / Flutter — Compilar Android` (corre si el #1 pasó)
   - `CI / Flutter — Compilar Web` (corre si el #1 pasó)
   - `CI / Cloud Functions legadas — CI`
4. Click en cada una para ver el log.
5. En la sección "Artifacts" del run encuentras `reporte-cobertura-lcov`, `app-release-bundle` y `web-build`.

## Evidencia

- Workflow definition: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml).
- Captura de un run exitoso: [`capturas/`](capturas/) (pendiente de agregar tras el primer push post-migración).
