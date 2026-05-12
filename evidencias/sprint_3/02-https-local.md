# Sprint 3 · HTTPS local y en producción

## En producción
La app se despliega a **Firebase Hosting**, que termina TLS en sus servidores con un certificado de Google. La configuración en [`firebase.json`](../../firebase.json) agrega además **HSTS** para forzar HTTPS en visitas subsecuentes:

```json
{
  "key": "Strict-Transport-Security",
  "value": "max-age=31536000; includeSubDomains; preload"
}
```

`max-age=31536000` (1 año) + `preload` lo hace candidato a la lista preload de Chrome, lo cual significa que el navegador **rechaza HTTP** incluso antes de la primera visita.

## Redirección desde el cliente
[`web/index.html`](../../web/index.html) incluye un guard al inicio del bootstrap que redirige cualquier `http://` (excepto `localhost`) a `https://`:

```js
(function enforceSecureOrigin() {
  var hostname = window.location.hostname;
  var isLocalhost = hostname === 'localhost' || ...;
  if (!isLocalhost && window.location.protocol === 'http:') {
    window.location.replace('https://' + ...);
  }
})();
```

Es una segunda línea de defensa: si por alguna razón HSTS no aplicó (primera visita, navegador viejo), el script igual fuerza HTTPS.

## En el código Dart
[`lib/core/config/env.dart`](../../lib/core/config/env.dart) **valida** la URL base al iniciar:

```dart
if (isProduction && !resolvedBaseUrl.startsWith('https://')) {
  throw StateError(
    'BASE_URL debe usar HTTPS en produccion. Valor recibido: $resolvedBaseUrl',
  );
}
```

Si alguien deploya un build de release con `--dart-define=BASE_URL=http://...` por error, la app **no arranca**. Falla rápido.

## Desarrollo local

### Opción 1 — Emulador con HTTP (default)
Para iterar rápido durante development, los emuladores corren en HTTP. La política de `web/index.html` deja pasar `localhost`. Esto es suficiente para los talleres internos.

```sh
firebase emulators:start --only functions,hosting
flutter run -d chrome
```

### Opción 2 — HTTPS local con `mkcert`
Cuando se necesita probar flujos que dependen de `Secure` cookies o de las APIs `crypto.subtle` (que requieren contexto seguro):

```sh
# 1. Instalar mkcert (https://github.com/FiloSottile/mkcert)
mkcert -install
mkcert localhost 127.0.0.1

# 2. Servir el build con un servidor que acepte cert/key
flutter build web
npx http-server build/web -S -C localhost+1.pem -K localhost+1-key.pem -p 5000
```

`mkcert` instala una CA local que el navegador confía, así que `https://localhost:5000` se ve verde sin warning.

## Validación
- `https://andicrochett-bcb21.web.app` carga con candado en verde — TLS provisto por Firebase Hosting.
- En el inspector → Network → cualquier asset: ver header `strict-transport-security: max-age=31536000; includeSubDomains; preload`.
- Forzar `http://andicrochett-bcb21.web.app` redirige a `https://` automáticamente (HSTS).
