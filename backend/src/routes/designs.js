const express = require('express');
const db = require('../db');
const { verifyFirebaseToken } = require('../auth');

const router = express.Router();
router.use(verifyFirebaseToken);

function nowIso() { return new Date().toISOString(); }

router.get('/', (_req, res) => {
  const rows = db.prepare(`
    SELECT * FROM designs ORDER BY fecha_creacion DESC
  `).all();
  res.json(rows);
});

router.get('/:id', (req, res) => {
  const row = db.prepare('SELECT * FROM designs WHERE id = ?').get(Number(req.params.id));
  if (!row) return res.status(404).json({ error: 'Diseño no encontrado' });
  res.json(row);
});

router.post('/', (req, res) => {
  const { nombre, descripcion } = req.body;
  if (!nombre || !nombre.trim()) {
    return res.status(400).json({ error: 'El campo "nombre" es requerido' });
  }

  const now = nowIso();
  const result = db.prepare(`
    INSERT INTO designs (nombre, descripcion, usuario_id, fecha_creacion, fecha_actualizacion)
    VALUES (?, ?, ?, ?, ?)
  `).run(nombre, descripcion || '', req.user.uid, now, now);

  const created = db.prepare('SELECT * FROM designs WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(created);
});

router.put('/:id', (req, res) => {
  const id = Number(req.params.id);
  const existing = db.prepare('SELECT * FROM designs WHERE id = ?').get(id);
  if (!existing) return res.status(404).json({ error: 'Diseño no encontrado' });

  const nombre = req.body.nombre ?? existing.nombre;
  const descripcion = req.body.descripcion ?? existing.descripcion;

  db.prepare(`
    UPDATE designs SET nombre = ?, descripcion = ?, fecha_actualizacion = ?
    WHERE id = ?
  `).run(nombre, descripcion, nowIso(), id);

  const updated = db.prepare('SELECT * FROM designs WHERE id = ?').get(id);
  res.json(updated);
});

router.delete('/:id', (req, res) => {
  const id = Number(req.params.id);
  const result = db.prepare('DELETE FROM designs WHERE id = ?').run(id);
  if (result.changes === 0) return res.status(404).json({ error: 'Diseño no encontrado' });
  res.status(204).send();
});

module.exports = router;
