const express = require('express');
const db = require('../db');
const { verifyFirebaseToken } = require('../auth');

const router = express.Router();
router.use(verifyFirebaseToken);

const VALID_TYPES = new Set(['circular', 'rows', 'mixed']);
const VALID_DIFFICULTIES = new Set(['beginner', 'intermediate', 'advanced', 'expert']);
const VALID_STATUSES = new Set(['draft', 'finished']);

function nowIso() { return new Date().toISOString(); }

function validatePayload(body, { partial = false } = {}) {
  const errors = [];
  const required = ['nombre', 'tipo', 'design_id'];

  if (!partial) {
    for (const field of required) {
      if (body[field] === undefined || body[field] === null || body[field] === '') {
        errors.push(`Falta el campo "${field}"`);
      }
    }
  }

  if (body.tipo !== undefined && !VALID_TYPES.has(body.tipo)) {
    errors.push(`"tipo" debe ser uno de: ${[...VALID_TYPES].join(', ')}`);
  }
  if (body.dificultad !== undefined && !VALID_DIFFICULTIES.has(body.dificultad)) {
    errors.push(`"dificultad" debe ser uno de: ${[...VALID_DIFFICULTIES].join(', ')}`);
  }
  if (body.estado !== undefined && !VALID_STATUSES.has(body.estado)) {
    errors.push(`"estado" debe ser uno de: ${[...VALID_STATUSES].join(', ')}`);
  }

  return errors;
}

router.get('/', (req, res) => {
  const { designId } = req.query;

  if (designId) {
    const rows = db.prepare(`
      SELECT * FROM patterns WHERE design_id = ? ORDER BY fecha_creacion DESC
    `).all(Number(designId));
    return res.json(rows);
  }

  const rows = db.prepare('SELECT * FROM patterns ORDER BY fecha_creacion DESC').all();
  res.json(rows);
});

router.get('/:id', (req, res) => {
  const row = db.prepare('SELECT * FROM patterns WHERE id = ?').get(Number(req.params.id));
  if (!row) return res.status(404).json({ error: 'Patrón no encontrado' });
  res.json(row);
});

router.post('/', (req, res) => {
  const errors = validatePayload(req.body);
  if (errors.length) return res.status(400).json({ errors });

  const design = db.prepare('SELECT id FROM designs WHERE id = ?').get(Number(req.body.design_id));
  if (!design) {
    return res.status(400).json({ error: 'El design_id no existe' });
  }

  const now = nowIso();
  const result = db.prepare(`
    INSERT INTO patterns (
      nombre, tipo, design_id, dificultad, material_sugerido, tamano_gancho,
      estado, texto_patron, usuario_id, fecha_creacion, fecha_actualizacion
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    req.body.nombre,
    req.body.tipo,
    Number(req.body.design_id),
    req.body.dificultad || 'beginner',
    req.body.material_sugerido || '',
    req.body.tamano_gancho || '',
    req.body.estado || 'draft',
    req.body.texto_patron || '',
    req.user.uid,
    now, now,
  );

  const created = db.prepare('SELECT * FROM patterns WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(created);
});

router.put('/:id', (req, res) => {
  const id = Number(req.params.id);
  const existing = db.prepare('SELECT * FROM patterns WHERE id = ?').get(id);
  if (!existing) return res.status(404).json({ error: 'Patrón no encontrado' });

  const errors = validatePayload(req.body, { partial: true });
  if (errors.length) return res.status(400).json({ errors });

  if (req.body.design_id !== undefined && Number(req.body.design_id) !== existing.design_id) {
    const design = db.prepare('SELECT id FROM designs WHERE id = ?').get(Number(req.body.design_id));
    if (!design) return res.status(400).json({ error: 'El design_id no existe' });
  }

  const merged = {
    nombre: req.body.nombre ?? existing.nombre,
    tipo: req.body.tipo ?? existing.tipo,
    design_id: req.body.design_id ?? existing.design_id,
    dificultad: req.body.dificultad ?? existing.dificultad,
    material_sugerido: req.body.material_sugerido ?? existing.material_sugerido,
    tamano_gancho: req.body.tamano_gancho ?? existing.tamano_gancho,
    estado: req.body.estado ?? existing.estado,
    texto_patron: req.body.texto_patron ?? existing.texto_patron,
  };

  db.prepare(`
    UPDATE patterns SET
      nombre = ?, tipo = ?, design_id = ?, dificultad = ?,
      material_sugerido = ?, tamano_gancho = ?, estado = ?,
      texto_patron = ?, fecha_actualizacion = ?
    WHERE id = ?
  `).run(
    merged.nombre, merged.tipo, Number(merged.design_id), merged.dificultad,
    merged.material_sugerido, merged.tamano_gancho, merged.estado,
    merged.texto_patron, nowIso(), id,
  );

  const updated = db.prepare('SELECT * FROM patterns WHERE id = ?').get(id);
  res.json(updated);
});

router.delete('/:id', (req, res) => {
  const id = Number(req.params.id);
  const result = db.prepare('DELETE FROM patterns WHERE id = ?').run(id);
  if (result.changes === 0) return res.status(404).json({ error: 'Patrón no encontrado' });
  res.status(204).send();
});

module.exports = router;
