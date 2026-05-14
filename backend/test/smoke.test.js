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

// ─────────────────────────────────────────────────────────────────────────────
//  Regresión: POST /api/orders con cliente_id=0 debe funcionar
//  (el formulario actual no tiene picker de clientes y manda 0 por defecto).
// ─────────────────────────────────────────────────────────────────────────────

test('POST /api/orders con cliente_id=0 y sin items → 201 (cliente_id normalizado a null)', async () => {
  const res = await request(app)
    .post('/api/orders')
    .set('Authorization', 'Bearer test-user-1')
    .send({
      cliente_id: 0,
      nombre_cliente: 'Cliente sin registrar',
      total: 250,
      estado: 'pending',
      items: [],
    });

  assert.equal(res.status, 201);
  assert.equal(res.body.cliente_id, null);
  assert.equal(res.body.nombre_cliente, 'Cliente sin registrar');
  assert.equal(res.body.total, 250);
});

test('POST /api/orders con producto_id inexistente → 400 con mensaje claro', async () => {
  const res = await request(app)
    .post('/api/orders')
    .set('Authorization', 'Bearer test-user-1')
    .send({
      cliente_id: 0,
      nombre_cliente: 'X',
      total: 100,
      items: [{ producto_id: 99999, nombre_producto: 'Falso', cantidad: 1, precio_unitario: 100 }],
    });

  assert.equal(res.status, 400);
  assert.match(res.body.error, /no existe/);
});

// ─────────────────────────────────────────────────────────────────────────────
//  Seguridad: audit_log + endpoint /api/analytics/security
// ─────────────────────────────────────────────────────────────────────────────

test('POST /api/security/login-attempt es público y registra el intento', async () => {
  const ok = await request(app)
    .post('/api/security/login-attempt')
    .send({ email: 'usuario@example.com', success: true });
  assert.equal(ok.status, 201);
  assert.equal(ok.body.recorded, true);

  const fail = await request(app)
    .post('/api/security/login-attempt')
    .send({ email: 'atacante@example.com', success: false, errorMessage: 'wrong-password' });
  assert.equal(fail.status, 201);
});

test('GET /api/analytics/security agrega login_attempts y api_calls', async () => {
  // Generamos tráfico autenticado para tener api_calls registrados.
  await request(app).get('/api/designs').set('Authorization', 'Bearer test-user-1');
  await request(app).get('/api/designs').set('Authorization', 'Bearer test-user-1');

  const res = await request(app)
    .get('/api/analytics/security')
    .set('Authorization', 'Bearer test-user-1');

  assert.equal(res.status, 200);
  assert.ok(res.body.loginAttempts);
  assert.ok(res.body.apiCalls24h);
  assert.ok(Array.isArray(res.body.topEndpoints));
  assert.ok(Array.isArray(res.body.recentFailedLogins));

  // Tras los inserts de la prueba anterior tenemos al menos 2 intentos.
  assert.ok(res.body.loginAttempts.total >= 2);
  assert.ok(res.body.loginAttempts.successful >= 1);
  assert.ok(res.body.loginAttempts.failed >= 1);

  // Y las llamadas a /api/designs deben aparecer en el top.
  const designsEndpoint = res.body.topEndpoints.find(e => e.path === '/api/designs');
  assert.ok(designsEndpoint, 'esperaba /api/designs en topEndpoints');
  assert.ok(designsEndpoint.hits >= 2);
});

test('GET /api/analytics/dashboard incluye productsNeedingRestock', async () => {
  // Creamos un producto con stock bajo para validar la query.
  await request(app)
    .post('/api/products')
    .set('Authorization', 'Bearer test-user-1')
    .send({ nombre: 'Estambre rojo', precio: 30, cantidad: 2 });

  const res = await request(app)
    .get('/api/analytics/dashboard')
    .set('Authorization', 'Bearer test-user-1');

  assert.equal(res.status, 200);
  assert.ok(Array.isArray(res.body.productsNeedingRestock));
  const lowStock = res.body.productsNeedingRestock.find(
    p => p.name === 'Estambre rojo',
  );
  assert.ok(lowStock, 'esperaba "Estambre rojo" en productsNeedingRestock');
  assert.equal(lowStock.status, 'low_stock');
  assert.equal(lowStock.currentStock, 2);
});
