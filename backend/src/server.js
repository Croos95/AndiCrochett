require('dotenv').config();

const http = require('http');
const https = require('https');

const { createApp } = require('./app');
const { ensureCert } = require('./https');

const app = createApp();

const httpPort = Number(process.env.PORT) || 3000;
const httpsPort = Number(process.env.HTTPS_PORT) || null;

http.createServer(app).listen(httpPort, () => {
  // eslint-disable-next-line no-console
  console.log(`[server] HTTP  → http://localhost:${httpPort}`);
});

if (httpsPort) {
  ensureCert()
    .then(({ cert, key }) => {
      https.createServer({ cert, key }, app).listen(httpsPort, () => {
        // eslint-disable-next-line no-console
        console.log(`[server] HTTPS → https://localhost:${httpsPort} (cert auto-firmado)`);
      });
    })
    .catch((err) => {
      // eslint-disable-next-line no-console
      console.error('[server] No se pudo levantar HTTPS:', err.message);
    });
}
