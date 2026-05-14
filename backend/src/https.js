// Soporte HTTPS para desarrollo local. Genera (o lee) un certificado
// auto-firmado y lo cachea en `backend/certs/` para que vivan entre reinicios.
//
// El cert NO se confía por defecto en navegadores ni clientes — espera ver
// `NET::ERR_CERT_AUTHORITY_INVALID` en Chrome o `--insecure` en curl. Lo
// importante es probar que el handshake TLS funciona y que las cabeceras
// `Strict-Transport-Security` aparecen.

const fs = require('fs');
const path = require('path');
const selfsigned = require('selfsigned');

const CERT_DIR = path.join(__dirname, '..', 'certs');
const CERT_PATH = path.join(CERT_DIR, 'localhost.crt');
const KEY_PATH = path.join(CERT_DIR, 'localhost.key');

/** Devuelve `{ cert, key }`, generando si es la primera vez. */
async function ensureCert() {
  if (fs.existsSync(CERT_PATH) && fs.existsSync(KEY_PATH)) {
    return {
      cert: fs.readFileSync(CERT_PATH),
      key: fs.readFileSync(KEY_PATH),
    };
  }

  // eslint-disable-next-line no-console
  console.log('[https] Generando certificado auto-firmado en', CERT_DIR);

  fs.mkdirSync(CERT_DIR, { recursive: true });

  // selfsigned v5: la API es async (devuelve Promise<GenerateResult>).
  const generated = await selfsigned.generate(
    [{ name: 'commonName', value: 'localhost' }],
    {
      days: 365,
      keySize: 2048,
      algorithm: 'sha256',
      extensions: [
        {
          name: 'subjectAltName',
          altNames: [
            { type: 2, value: 'localhost' },     // DNS
            { type: 7, ip: '127.0.0.1' },        // IP
            { type: 7, ip: '10.0.2.2' },         // Android emulator → host
          ],
        },
      ],
    },
  );

  fs.writeFileSync(CERT_PATH, generated.cert, { mode: 0o644 });
  fs.writeFileSync(KEY_PATH, generated.private, { mode: 0o600 });

  return { cert: generated.cert, key: generated.private };
}

module.exports = { ensureCert };
