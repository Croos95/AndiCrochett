const express = require('express');
const db = require('../db');
const { verifyFirebaseToken } = require('../auth');

const router = express.Router();
router.use(verifyFirebaseToken);

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
  });
});

module.exports = router;
