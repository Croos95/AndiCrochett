const express = require('express');
const db = require('../db');
const { verifyFirebaseToken } = require('../auth');

const router = express.Router();
router.use(verifyFirebaseToken);

const VALID_STATUSES = new Set(['available', 'low_stock', 'out_of_stock']);

function nowIso() { return new Date().toISOString(); }

function computeStatus(quantity) {
  if (quantity <= 0) return 'out_of_stock';
  if (quantity <= 5) return 'low_stock';
  return 'available';
}

router.get('/', (req, res) => {
  const { q, categoria } = req.query;

  if (q) {
    const like = `%${q}%`;
    const rows = db.prepare(`
      SELECT * FROM productos
      WHERE nombre LIKE ? OR descripcion LIKE ? OR categoria LIKE ?
      ORDER BY nombre ASC
    `).all(like, like, like);
    return res.json(rows);
  }

  if (categoria) {
    const rows = db.prepare(`
      SELECT * FROM productos WHERE categoria = ? ORDER BY nombre ASC
    `).all(categoria);
    return res.json(rows);
  }

  const rows = db.prepare('SELECT * FROM productos ORDER BY nombre ASC').all();
  res.json(rows);
});

router.get('/:id', (req, res) => {
  const row = db.prepare('SELECT * FROM productos WHERE id = ?').get(Number(req.params.id));
  if (!row) return res.status(404).json({ error: 'Producto no encontrado' });
  res.json(row);
});

router.post('/', (req, res) => {
  const { nombre, precio } = req.body;
  if (!nombre || !nombre.trim()) {
    return res.status(400).json({ error: 'El campo "nombre" es requerido' });
  }
  if (precio === undefined || precio === null || isNaN(Number(precio))) {
    return res.status(400).json({ error: 'El campo "precio" es requerido y debe ser numérico' });
  }

  const cantidad = Number(req.body.cantidad ?? 0);
  const estadoEntrada = req.body.estado;
  const estado = (estadoEntrada && VALID_STATUSES.has(estadoEntrada))
    ? estadoEntrada
    : computeStatus(cantidad);

  const now = nowIso();
  try {
    const result = db.prepare(`
      INSERT INTO productos (
        nombre, descripcion, precio, imagen, categoria, color, peso, marca,
        cantidad, estado, fecha_creacion, fecha_actualizacion
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      nombre,
      req.body.descripcion || '',
      Number(precio),
      req.body.imagen || '',
      req.body.categoria || '',
      req.body.color || '',
      req.body.peso || '',
      req.body.marca || '',
      cantidad,
      estado,
      now, now,
    );
    const created = db.prepare('SELECT * FROM productos WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(created);
  } catch (err) {
    if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ error: 'Ya existe un producto con ese nombre' });
    }
    throw err;
  }
});

router.put('/:id', (req, res) => {
  const id = Number(req.params.id);
  const existing = db.prepare('SELECT * FROM productos WHERE id = ?').get(id);
  if (!existing) return res.status(404).json({ error: 'Producto no encontrado' });

  const cantidad = req.body.cantidad !== undefined ? Number(req.body.cantidad) : existing.cantidad;
  const estadoEntrada = req.body.estado;
  const estado = (estadoEntrada && VALID_STATUSES.has(estadoEntrada))
    ? estadoEntrada
    : (req.body.cantidad !== undefined ? computeStatus(cantidad) : existing.estado);

  const merged = {
    nombre: req.body.nombre ?? existing.nombre,
    descripcion: req.body.descripcion ?? existing.descripcion,
    precio: req.body.precio !== undefined ? Number(req.body.precio) : existing.precio,
    imagen: req.body.imagen ?? existing.imagen,
    categoria: req.body.categoria ?? existing.categoria,
    color: req.body.color ?? existing.color,
    peso: req.body.peso ?? existing.peso,
    marca: req.body.marca ?? existing.marca,
    cantidad,
    estado,
  };

  try {
    db.prepare(`
      UPDATE productos SET
        nombre = ?, descripcion = ?, precio = ?, imagen = ?, categoria = ?,
        color = ?, peso = ?, marca = ?, cantidad = ?, estado = ?,
        fecha_actualizacion = ?
      WHERE id = ?
    `).run(
      merged.nombre, merged.descripcion, merged.precio, merged.imagen, merged.categoria,
      merged.color, merged.peso, merged.marca, merged.cantidad, merged.estado,
      nowIso(), id,
    );
    const updated = db.prepare('SELECT * FROM productos WHERE id = ?').get(id);
    res.json(updated);
  } catch (err) {
    if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ error: 'Ya existe otro producto con ese nombre' });
    }
    throw err;
  }
});

router.patch('/:id/stock', (req, res) => {
  const id = Number(req.params.id);
  const { cantidad } = req.body;
  if (cantidad === undefined || isNaN(Number(cantidad))) {
    return res.status(400).json({ error: '"cantidad" requerida y numérica' });
  }
  const newQty = Number(cantidad);
  if (newQty < 0) return res.status(400).json({ error: 'La cantidad no puede ser negativa' });

  const existing = db.prepare('SELECT id FROM productos WHERE id = ?').get(id);
  if (!existing) return res.status(404).json({ error: 'Producto no encontrado' });

  db.prepare(`
    UPDATE productos SET cantidad = ?, estado = ?, fecha_actualizacion = ?
    WHERE id = ?
  `).run(newQty, computeStatus(newQty), nowIso(), id);

  const updated = db.prepare('SELECT * FROM productos WHERE id = ?').get(id);
  res.json(updated);
});

router.post('/:id/adjust-stock', (req, res) => {
  const id = Number(req.params.id);
  const { delta } = req.body;
  if (delta === undefined || isNaN(Number(delta))) {
    return res.status(400).json({ error: '"delta" requerido y numérico' });
  }

  const existing = db.prepare('SELECT cantidad FROM productos WHERE id = ?').get(id);
  if (!existing) return res.status(404).json({ error: 'Producto no encontrado' });

  const newQty = existing.cantidad + Number(delta);
  if (newQty < 0) return res.status(400).json({ error: 'El stock no puede ser negativo' });

  db.prepare(`
    UPDATE productos SET cantidad = ?, estado = ?, fecha_actualizacion = ?
    WHERE id = ?
  `).run(newQty, computeStatus(newQty), nowIso(), id);

  const updated = db.prepare('SELECT * FROM productos WHERE id = ?').get(id);
  res.json(updated);
});

router.delete('/:id', (req, res) => {
  const id = Number(req.params.id);
  const result = db.prepare('DELETE FROM productos WHERE id = ?').run(id);
  if (result.changes === 0) return res.status(404).json({ error: 'Producto no encontrado' });
  res.status(204).send();
});

module.exports = router;
