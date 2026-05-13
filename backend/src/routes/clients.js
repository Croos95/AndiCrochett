const express = require('express');
const db = require('../db');
const { verifyFirebaseToken } = require('../auth');

const router = express.Router();
router.use(verifyFirebaseToken);

router.get('/', (_req, res) => {
  const rows = db.prepare('SELECT * FROM clientes ORDER BY nombre ASC').all();
  res.json(rows);
});

router.get('/:id', (req, res) => {
  const row = db.prepare('SELECT * FROM clientes WHERE id = ?').get(Number(req.params.id));
  if (!row) return res.status(404).json({ error: 'Cliente no encontrado' });
  res.json(row);
});

router.post('/', (req, res) => {
  const { nombre, email, telefono, direccion } = req.body;
  if (!nombre || !nombre.trim()) {
    return res.status(400).json({ error: 'El campo "nombre" es requerido' });
  }

  try {
    const result = db.prepare(`
      INSERT INTO clientes (nombre, email, telefono, direccion)
      VALUES (?, ?, ?, ?)
    `).run(nombre, email || null, telefono || null, direccion || null);

    const created = db.prepare('SELECT * FROM clientes WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(created);
  } catch (err) {
    if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ error: 'Ya existe un cliente con ese email' });
    }
    throw err;
  }
});

router.put('/:id', (req, res) => {
  const id = Number(req.params.id);
  const existing = db.prepare('SELECT * FROM clientes WHERE id = ?').get(id);
  if (!existing) return res.status(404).json({ error: 'Cliente no encontrado' });

  const merged = {
    nombre: req.body.nombre ?? existing.nombre,
    email: req.body.email !== undefined ? (req.body.email || null) : existing.email,
    telefono: req.body.telefono !== undefined ? (req.body.telefono || null) : existing.telefono,
    direccion: req.body.direccion !== undefined ? (req.body.direccion || null) : existing.direccion,
  };

  try {
    db.prepare(`
      UPDATE clientes SET nombre = ?, email = ?, telefono = ?, direccion = ?
      WHERE id = ?
    `).run(merged.nombre, merged.email, merged.telefono, merged.direccion, id);

    const updated = db.prepare('SELECT * FROM clientes WHERE id = ?').get(id);
    res.json(updated);
  } catch (err) {
    if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ error: 'Ya existe otro cliente con ese email' });
    }
    throw err;
  }
});

router.delete('/:id', (req, res) => {
  const id = Number(req.params.id);
  const result = db.prepare('DELETE FROM clientes WHERE id = ?').run(id);
  if (result.changes === 0) return res.status(404).json({ error: 'Cliente no encontrado' });
  res.status(204).send();
});

module.exports = router;
