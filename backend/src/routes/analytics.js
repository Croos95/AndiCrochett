const express = require('express');
const db = require('../db');
const { verifyFirebaseToken } = require('../auth');

const router = express.Router();
router.use(verifyFirebaseToken);

// ─────────────────────────────────────────────────────────────────────────────
//  /api/analytics/security — métricas de ciberseguridad (audit_log)
// ─────────────────────────────────────────────────────────────────────────────

router.get('/security', (_req, res) => {
  const day = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const week = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

  const loginAttempts = db.prepare(`
    SELECT
      COUNT(*) AS total,
      SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) AS successful,
      SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) AS failed
    FROM audit_log
    WHERE event_type = 'login_attempt' AND timestamp >= ?
  `).get(week);

  const apiCalls = db.prepare(`
    SELECT
      COUNT(*) AS total,
      SUM(CASE WHEN status_code >= 200 AND status_code < 400 THEN 1 ELSE 0 END) AS ok,
      SUM(CASE WHEN status_code = 401 OR status_code = 403 THEN 1 ELSE 0 END) AS unauthorized,
      SUM(CASE WHEN status_code >= 500 THEN 1 ELSE 0 END) AS server_errors,
      AVG(duration_ms) AS avg_duration_ms
    FROM audit_log
    WHERE event_type = 'api_call' AND timestamp >= ?
  `).get(day);

  const topEndpoints = db.prepare(`
    SELECT method, path, COUNT(*) AS hits
    FROM audit_log
    WHERE event_type = 'api_call' AND timestamp >= ?
    GROUP BY method, path
    ORDER BY hits DESC
    LIMIT 5
  `).all(day);

  const failedLogins = db.prepare(`
    SELECT timestamp, email, error_message, ip_address
    FROM audit_log
    WHERE event_type = 'login_attempt' AND success = 0 AND timestamp >= ?
    ORDER BY timestamp DESC
    LIMIT 10
  `).all(week);

  res.json({
    loginAttempts: {
      total: Number(loginAttempts.total) || 0,
      successful: Number(loginAttempts.successful) || 0,
      failed: Number(loginAttempts.failed) || 0,
    },
    apiCalls24h: {
      total: Number(apiCalls.total) || 0,
      ok: Number(apiCalls.ok) || 0,
      unauthorized: Number(apiCalls.unauthorized) || 0,
      serverErrors: Number(apiCalls.server_errors) || 0,
      avgDurationMs: Number(apiCalls.avg_duration_ms) || 0,
    },
    topEndpoints: topEndpoints.map(r => ({
      method: r.method,
      path: r.path,
      hits: Number(r.hits),
    })),
    recentFailedLogins: failedLogins.map(r => ({
      timestamp: r.timestamp,
      email: r.email,
      errorMessage: r.error_message,
      ipAddress: r.ip_address,
    })),
  });
});

router.get('/dashboard', (_req, res) => {
  const totalProducts = db.prepare('SELECT COUNT(*) AS c FROM productos').get().c;
  const lowStockCount = db.prepare(
    `SELECT COUNT(*) AS c FROM productos WHERE estado = 'low_stock'`
  ).get().c;
  const outOfStockCount = db.prepare(
    `SELECT COUNT(*) AS c FROM productos WHERE estado = 'out_of_stock'`
  ).get().c;
  const totalOrders = db.prepare('SELECT COUNT(*) AS c FROM pedidos').get().c;
  const totalClients = db.prepare('SELECT COUNT(*) AS c FROM clientes').get().c;

  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const revenueRow = db.prepare(`
    SELECT COALESCE(SUM(total), 0) AS total
    FROM pedidos
    WHERE estado = 'completed' AND fecha_pedido >= ?
  `).get(cutoff);
  const revenueLast30Days = Number(revenueRow.total) || 0;

  const ordersByStatus = db.prepare(`
    SELECT estado AS status, COUNT(*) AS c
    FROM pedidos
    GROUP BY estado
    ORDER BY c DESC
  `).all();

  const topProducts = db.prepare(`
    SELECT nombre_producto AS nombre,
           SUM(cantidad) AS units,
           SUM(cantidad * precio_unitario) AS revenue
    FROM items_pedido
    GROUP BY nombre_producto
    ORDER BY units DESC
    LIMIT 5
  `).all();

  // Productos que requieren reposición: low_stock primero, luego out_of_stock.
  // Útil para que el dueño vea qué pedir al proveedor.
  const productsNeedingRestock = db.prepare(`
    SELECT id, nombre, cantidad, estado
    FROM productos
    WHERE estado IN ('low_stock', 'out_of_stock')
    ORDER BY
      CASE estado WHEN 'out_of_stock' THEN 0 ELSE 1 END,
      cantidad ASC,
      nombre ASC
    LIMIT 10
  `).all();

  res.json({
    totalProducts,
    lowStockCount,
    outOfStockCount,
    totalOrders,
    totalClients,
    revenueLast30Days,
    ordersByStatus: ordersByStatus.map(r => ({
      statusKey: r.status,
      count: Number(r.c),
    })),
    topProducts: topProducts.map(r => ({
      name: r.nombre,
      unitsSold: Number(r.units || 0),
      revenue: Number(r.revenue || 0),
    })),
    productsNeedingRestock: productsNeedingRestock.map(r => ({
      id: Number(r.id),
      name: r.nombre,
      currentStock: Number(r.cantidad),
      status: r.estado,
    })),
  });
});

module.exports = router;
