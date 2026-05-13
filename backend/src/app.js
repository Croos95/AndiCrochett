// Define la aplicación Express sin arrancar el listener. Esto permite
// importarla desde tests (supertest) sin abrir un puerto real.

const express = require('express');
const cors = require('cors');

require('./db');

const patternsRouter = require('./routes/patterns');
const designsRouter = require('./routes/designs');
const productsRouter = require('./routes/products');
const clientsRouter = require('./routes/clients');
const ordersRouter = require('./routes/orders');
const catalogRouter = require('./routes/catalog');
const analyticsRouter = require('./routes/analytics');

function createApp() {
  const app = express();

  app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
  app.use(express.json({ limit: '2mb' }));

  // Silenciamos el logger durante los tests para mantener la salida limpia.
  if (process.env.NODE_ENV !== 'test') {
    app.use((req, res, next) => {
      const start = Date.now();
      res.on('finish', () => {
        const ms = Date.now() - start;
        // eslint-disable-next-line no-console
        console.log(`${req.method} ${req.originalUrl} → ${res.statusCode} (${ms}ms)`);
      });
      next();
    });
  }

  app.get('/health', (_req, res) => {
    res.json({ ok: true, service: 'andicrochett-backend' });
  });

  app.use('/api/patterns', patternsRouter);
  app.use('/api/designs', designsRouter);
  app.use('/api/products', productsRouter);
  app.use('/api/clients', clientsRouter);
  app.use('/api/orders', ordersRouter);
  app.use('/api/catalog', catalogRouter);
  app.use('/api/analytics', analyticsRouter);

  app.use((req, res) => {
    res.status(404).json({ error: `Ruta no encontrada: ${req.method} ${req.path}` });
  });

  // eslint-disable-next-line no-unused-vars
  app.use((err, _req, res, _next) => {
    // eslint-disable-next-line no-console
    console.error('[error]', err);
    res.status(500).json({ error: err.message || 'Error interno del servidor' });
  });

  return app;
}

module.exports = { createApp };
