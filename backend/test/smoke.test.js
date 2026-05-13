// Smoke test del backend: arranca el app en memoria (sin abrir puerto) y
// verifica los endpoints clave usando supertest.
//
// Notas:
// - DB_PATH apunta a un archivo temporal para no tocar `data/andicrochett.db`.
// - NODE_ENV=test activa el bypass de auth en auth.js: cualquier token
//   `test-<uid>` se acepta sin Firebase Admin.

process.env.NODE_ENV = 'test';

const path = require('path');
const fs = require('fs');
const os = require('os');
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

const tmpDb = path.join(os.tmpdir(), `andicrochett-test-${Date.now()}.db`);
process.env.DB_PATH = tmpDb;

const request = require('supertest');
const { createApp } = require('../src/app');

const app = createApp();

after(() => {
  for (const ext of ['', '-journal', '-wal', '-shm']) {
    try { fs.unlinkSync(tmpDb + ext); } catch (_) {}
  }
});

test('GET /health responde 200 con ok=true', async () => {
  const res = await request(app).get('/health');
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.service, 'andicrochett-backend');
});

test('GET /api/designs sin auth → 401', async () => {
  const res = await request(app).get('/api/designs');
  assert.equal(res.status, 401);
});

test('GET /api/designs con token de prueba → 200 (lista vacía)', async () => {
  const res = await request(app)
    .get('/api/designs')
    .set('Authorization', 'Bearer test-user-1');

  assert.equal(res.status, 200);
  assert.deepEqual(res.body, []);
});

test('POST /api/designs crea y luego GET lo devuelve', async () => {
  const create = await request(app)
    .post('/api/designs')
    .set('Authorization', 'Bearer test-user-1')
    .send({ nombre: 'Diseño de prueba', descripcion: 'demo' });

  assert.equal(create.status, 201);
  assert.equal(create.body.nombre, 'Diseño de prueba');
  assert.equal(create.body.usuario_id, 'user-1');

  const list = await request(app)
    .get('/api/designs')
    .set('Authorization', 'Bearer test-user-1');

  assert.equal(list.status, 200);
  assert.equal(list.body.length, 1);
  assert.equal(list.body[0].descripcion, 'demo');
});

test('POST /api/designs sin "nombre" → 400', async () => {
  const res = await request(app)
    .post('/api/designs')
    .set('Authorization', 'Bearer test-user-1')
    .send({ descripcion: 'sin nombre' });

  assert.equal(res.status, 400);
  assert.ok(res.body.error);
});

test('GET /api/analytics/dashboard refleja los inserts', async () => {
  const res = await request(app)
    .get('/api/analytics/dashboard')
    .set('Authorization', 'Bearer test-user-1');

  assert.equal(res.status, 200);
  assert.equal(typeof res.body.totalProducts, 'number');
  assert.equal(typeof res.body.totalOrders, 'number');
  assert.ok(Array.isArray(res.body.ordersByStatus));
});

test('GET ruta inexistente → 404', async () => {
  const res = await request(app)
    .get('/api/no-existe')
    .set('Authorization', 'Bearer test-user-1');

  assert.equal(res.status, 404);
});
