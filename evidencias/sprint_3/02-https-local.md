# Sprint 3 · HTTPS local y en producción

## HTTPS local — opt-in con cert auto-firmado

El backend Node soporta HTTPS además del HTTP por defecto, cuando se setea la variable `HTTPS_PORT`:

```sh
cd backend
npm run dev:https           # arranca HTTP:3000 + HTTPS:3443
```

Salida esperada:
```
[https] Generando certificado auto-firmado en backend/certs   (solo primera vez)
[server] HTTP  → http://localhost:3000
[server] HTTPS → https://localhost:3443 (cert auto-firmado)
```

### Cómo se genera el certificado

[`backend/src/https.js`](../../backend/src/https.js) usa el package [`selfsigned`](https://www.npmjs.com/package/selfsigned) (sin depender de OpenSSL del sistema). La primera vez genera un cert válido por 365 días y lo cachea en `backend/certs/`:

```js
const generated = await selfsigned.generate(
  [{ name: 'commonName', value: 'localhost' }],
  {
    days: 365,
    keySize: 2048,
    algorithm: 'sha256',
    extensions: [{
      name: 'subjectAltName',
      altNames: [
        { type: 2, value: 'localhost' },     // DNS
        { type: 7, ip: '127.0.0.1' },        // IP loopback
        { type: 7, ip: '10.0.2.2' },         // Android emulator → host
      ],
    }],
  },
);
```

Los archivos `localhost.crt` y `localhost.key` quedan en `backend/certs/` y están **excluidos del repo** vía `.gitignore` (las claves privadas no se commitean nunca).

### Probar que funciona

```sh
curl -k https://localhost:3443/health
# {"ok":true,"service":"andicrochett-backend"}

# El flag -k acepta el cert auto-firmado (insecure). En navegador verás
# "NET::ERR_CERT_AUTHORITY_INVALID" — acepta la advertencia para probar.
```

### HSTS inyectado por Helmet

Cuando la conexión es HTTPS, el header `Strict-Transport-Security: max-age=31536000; includeSubDomains` aparece en cada respuesta. En HTTP el header sigue presente pero los navegadores lo ignoran (HSTS solo se activa sobre TLS válido).

```sh
curl -k -I https://localhost:3443/health | grep -i strict
# Strict-Transport-Security: max-age=31536000; includeSubDomains
```

### Si quieres cert confiado (sin warnings)

`selfsigned` es suficiente para validar que TLS funciona, pero el navegador siempre muestra advertencia. Para desarrollo prolongado, instalar [`mkcert`](https://github.com/FiloSottile/mkcert):

```sh
mkcert -install                                              # instala CA local
mkcert localhost 127.0.0.1 10.0.2.2                          # genera cert confiado
mv localhost+2.pem backend/certs/localhost.crt
mv localhost+2-key.pem backend/certs/localhost.key
npm run dev:https
```

Ahora `https://localhost:3443` carga con candado verde sin warning.

## HTTPS en producción

### El cliente Flutter
[`lib/core/config/env.dart`](../../lib/core/config/env.dart) **valida** la URL base al iniciar:

```dart
if (isProduction) {
  if (resolvedBaseUrl.isEmpty) {
    throw StateError('BASE_URL no esta configurado para produccion...');
  }
  if (!resolvedBaseUrl.startsWith('https://')) {
    throw StateError('BASE_URL debe usar HTTPS en produccion...');
  }
}
```

Si alguien deploya un build de release con `--dart-define=BASE_URL=http://...` por error, la app **no arranca**. Falla rápido en el bootstrap.

### Android NetworkSecurityConfig
[`android/app/src/main/res/xml/network_security_config.xml`](../../android/app/src/main/res/xml/network_security_config.xml) permite cleartext (HTTP) **solo** para los hosts de desarrollo:

```xml
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

Y se referencia en el AndroidManifest:
```xml
<application android:networkSecurityConfig="@xml/network_security_config" ...>
```

Resultado: en debug el emulador puede pegarle a `http://10.0.2.2:3000`, pero en cualquier release contra producción **el sistema operativo bloquea HTTP** — solo HTTPS pasa.

### Backend en producción
Cuando se despliegue el backend (Railway / Render / VPS), el `HTTPS_PORT` se sustituye por el listener TLS que ofrezca el host. Railway y Render terminan TLS por ti — pones el backend en HTTP detrás del proxy y el certificado lo gestiona la plataforma.

## Validación

| Capa | Cómo se valida |
|---|---|
| Backend local | `curl -k https://localhost:3443/health` devuelve 200 + HSTS |
| Cliente Flutter (release) | Build de release con BASE_URL HTTP **explota al arrancar** |
| Android (release) | Cualquier request HTTP a IP no listada **es bloqueada por el SO** |
| Producción | Tu host (Railway/Render) emite cert Let's Encrypt automático |

## Histórico (referencia)

Originalmente este sprint cubría HTTPS vía Firebase Hosting + redirecciones en `web/index.html` para el frontend desplegado en `https://andicrochett-bcb21.web.app`. Esos artefactos siguen en el repo (`firebase.json`, `web/index.html`) por si se decide mantener el deploy de Firebase Hosting en paralelo. La cobertura del Sprint 3 ahora se centra en el backend Node propio.
