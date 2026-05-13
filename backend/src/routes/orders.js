const express = require('express');
const db = require('../db');
const { verifyFirebaseToken } = require('../auth');

const router = express.Router();
router.use(verifyFirebaseToken);

const VALID_STATUSES = new Set(['pending', 'inProgress', 'completed', 'cancelled']);

function nowIso() { return new Date().toISOString(); }

function computeProductStatus(quantity) {
  if (quantity <= 0) return 'out_of_stock';
  if (quantity <= 5) return 'low_stock';
  return 'available';
}

function loadOrderWithItems(id) {
  const order = db.prepare(`
    SELECT o.*, COALESCE(NULLIF(o.nombre_cliente,''), c.nombre, '') AS nombre_cliente
    FROM pedidos o
    LEFT JOIN clientes c ON o.cliente_id = c.id
    WHERE o.id = ?
  `).get(id);
  if (!order) return null;

  const items = db.prepare(`
    SELECT * FROM items_pedido WHERE pedido_id = ?
  `).all(id);

  return { ...order, items };
}

router.get('/', (_req, res) => {
  const orders = db.prepare(`
    SELECT o.*, COALESCE(NULLIF(o.nombre_cliente,''), c.nombre, '') AS nombre_cliente
    FROM pedidos o
    LEFT JOIN clientes c ON o.cliente_id = c.id
    ORDER BY o.fecha_pedido DESC
  `).all();

  const itemsByOrder = db.prepare(`
    SELECT * FROM items_pedido WHERE pedido_id IN (${orders.map(() => '?').join(',') || 'NULL'})
  `);

  if (orders.length === 0) return res.json([]);

  const allItems = itemsByOrder.all(...orders.map(o => o.id));
  const grouped = {};
  for (const item of allItems) {
    grouped[item.pedido_id] ??= [];
    grouped[item.pedido_id].push(item);
  }

  res.json(orders.map(o => ({ ...o, items: grouped[o.id] || [] })));
});

router.get('/:id', (req, res) => {
  const order = loadOrderWithItems(Number(req.params.id));
  if (!order) return res.status(404).json({ error: 'Pedido no encontrado' });
  res.json(order);
});

router.post('/', (req, res) => {
  const {
    cliente_id, nombre_cliente, fecha_entrega, total, estado,
    notas, contacto_cliente, items,
  } = req.body;

  if (total === undefined || isNaN(Number(total))) {
    return res.status(400).json({ error: '"total" requerido y numérico' });
  }
  if (estado && !VALID_STATUSES.has(estado)) {
    return res.status(400).json({ error: `"estado" inválido. Válidos: ${[...VALID_STATUSES].join(', ')}` });
  }
  if (items && !Array.isArray(items)) {
    return res.status(400).json({ error: '"items" debe ser un arreglo' });
  }

  const now = nowIso();
  const create = db.transaction(() => {
    const result = db.prepare(`
      INSERT INTO pedidos (
        usuario_id, cliente_id, nombre_cliente, fecha_pedido, fecha_entrega,
        total, estado, notas, contacto_cliente, items_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      req.user.uid,
      cliente_id ?? null,
      nombre_cliente || '',
      now,
      fecha_entrega || null,
      Number(total),
      estado || 'pending',
      notas || '',
      contacto_cliente || '',
      JSON.stringify(items || []),
    );

    const pedidoId = result.lastInsertRowid;

    for (const item of items || []) {
      db.prepare(`
        INSERT INTO items_pedido (pedido_id, producto_id, nombre_producto, cantidad, precio_unitario)
        VALUES (?, ?, ?, ?, ?)
      `).run(
        pedidoId,
        item.producto_id ?? null,
        item.nombre_producto || '',
        Number(item.cantidad ?? 0),
        Number(item.precio_unitario ?? 0),
      );

      if (item.producto_id != null) {
        const product = db.prepare('SELECT cantidad FROM productos WHERE id = ?').get(item.producto_id);
        if (product) {
          const newQty = product.cantidad - Number(item.cantidad ?? 0);
          db.prepare(`
            UPDATE productos SET cantidad = ?, estado = ?, fecha_actualizacion = ?
            WHERE id = ?
          `).run(newQty, computeProductStatus(newQty), now, item.producto_id);
        }
      }
    }

    return pedidoId;
  });

  try {
    const id = create();
    res.status(201).json(loadOrderWithItems(id));
  } catch (err) {
    console.error('[orders POST]', err);
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', (req, res) => {
  const id = Number(req.params.id);
  const existing = db.prepare('SELECT * FROM pedidos WHERE id = ?').get(id);
  if (!existing) return res.status(404).json({ error: 'Pedido no encontrado' });

  const {
    cliente_id, nombre_cliente, fecha_pedido, fecha_entrega, total, estado,
    notas, contacto_cliente, items,
  } = req.body;

  if (estado !== undefined && !VALID_STATUSES.has(estado)) {
    return res.status(400).json({ error: `"estado" inválido. Válidos: ${[...VALID_STATUSES].join(', ')}` });
  }
  if (items !== undefined && !Array.isArray(items)) {
    return res.status(400).json({ error: '"items" debe ser un arreglo' });
  }

  const merged = {
    cliente_id: cliente_id !== undefined ? cliente_id : existing.cliente_id,
    nombre_cliente: nombre_cliente ?? existing.nombre_cliente,
    fecha_pedido: fecha_pedido ?? existing.fecha_pedido,
    fecha_entrega: fecha_entrega !== undefined ? fecha_entrega : existing.fecha_entrega,
    total: total !== undefined ? Number(total) : existing.total,
    estado: estado ?? existing.estado,
    notas: notas ?? existing.notas,
    contacto_cliente: contacto_cliente ?? existing.contacto_cliente,
  };

  const updateTxn = db.transaction(() => {
    db.prepare(`
      UPDATE pedidos SET
        cliente_id = ?, nombre_cliente = ?, fecha_pedido = ?, fecha_entrega = ?,
        total = ?, estado = ?, notas = ?, contacto_cliente = ?,
        items_json = COALESCE(?, items_json)
      WHERE id = ?
    `).run(
      merged.cliente_id, merged.nombre_cliente, merged.fecha_pedido, merged.fecha_entrega,
      merged.total, merged.estado, merged.notas, merged.contacto_cliente,
      items !== undefined ? JSON.stringify(items) : null,
      id,
    );

    if (items !== undefined) {
      db.prepare('DELETE FROM items_pedido WHERE pedido_id = ?').run(id);
      for (const item of items) {
        db.prepare(`
          INSERT INTO items_pedido (pedido_id, producto_id, nombre_producto, cantidad, precio_unitario)
          VALUES (?, ?, ?, ?, ?)
        `).run(
          id,
          item.producto_id ?? null,
          item.nombre_producto || '',
          Number(item.cantidad ?? 0),
          Number(item.precio_unitario ?? 0),
        );
      }
    }
  });

  try {
    updateTxn();
    res.json(loadOrderWithItems(id));
  } catch (err) {
    console.error('[orders PUT]', err);
    res.status(500).json({ error: err.message });
  }
});

router.patch('/:id/status', (req, res) => {
  const id = Number(req.params.id);
  const { estado } = req.body;
  if (!estado || !VALID_STATUSES.has(estado)) {
    return res.status(400).json({ error: `"estado" requerido y válido: ${[...VALID_STATUSES].join(', ')}` });
  }
  const result = db.prepare('UPDATE pedidos SET estado = ? WHERE id = ?').run(estado, id);
  if (result.changes === 0) return res.status(404).json({ error: 'Pedido no encontrado' });
  res.json(loadOrderWithItems(id));
});

router.post('/:id/cancel', (req, res) => {
  const id = Number(req.params.id);
  const existing = db.prepare('SELECT id FROM pedidos WHERE id = ?').get(id);
  if (!existing) return res.status(404).json({ error: 'Pedido no encontrado' });

  const cancelTxn = db.transaction(() => {
    const items = db.prepare('SELECT * FROM items_pedido WHERE pedido_id = ?').all(id);
    const now = nowIso();

    for (const item of items) {
      if (item.producto_id != null) {
        const product = db.prepare('SELECT cantidad FROM productos WHERE id = ?').get(item.producto_id);
        if (product) {
          const newQty = product.cantidad + item.cantidad;
          db.prepare(`
            UPDATE productos SET cantidad = ?, estado = ?, fecha_actualizacion = ?
            WHERE id = ?
          `).run(newQty, computeProductStatus(newQty), now, item.producto_id);
        }
      }
    }

    db.prepare('DELETE FROM items_pedido WHERE pedido_id = ?').run(id);
    db.prepare('DELETE FROM pedidos WHERE id = ?').run(id);
  });

  try {
    cancelTxn();
    res.status(204).send();
  } catch (err) {
    console.error('[orders cancel]', err);
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', (req, res) => {
  const id = Number(req.params.id);
  const result = db.prepare('DELETE FROM pedidos WHERE id = ?').run(id);
  if (result.changes === 0) return res.status(404).json({ error: 'Pedido no encontrado' });
  res.status(204).send();
});

module.exports = router;
