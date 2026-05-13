const express = require('express');
const db = require('../db');
const { verifyFirebaseToken } = require('../auth');

const router = express.Router();
router.use(verifyFirebaseToken);

function nowIso() { return new Date().toISOString(); }

function jsonArray(value) {
  if (value === undefined || value === null) return undefined;
  if (Array.isArray(value)) return JSON.stringify(value);
  if (typeof value === 'string') return value;
  return JSON.stringify([]);
}

router.get('/me', (req, res) => {
  const row = db.prepare('SELECT * FROM catalog_settings WHERE usuario_id = ?').get(req.user.uid);
  if (!row) return res.json(null);
  res.json(row);
});

router.get('/:userId', (req, res) => {
  const row = db.prepare('SELECT * FROM catalog_settings WHERE usuario_id = ?').get(req.params.userId);
  if (!row) return res.status(404).json({ error: 'Catálogo no encontrado' });
  res.json(row);
});

router.put('/me', (req, res) => {
  const uid = req.user.uid;
  const existing = db.prepare('SELECT id FROM catalog_settings WHERE usuario_id = ?').get(uid);
  const now = nowIso();

  const data = {
    es_publico: req.body.es_publico !== undefined ? (req.body.es_publico ? 1 : 0) : undefined,
    nombre_negocio: req.body.nombre_negocio,
    email_contacto: req.body.email_contacto,
    telefono_contacto: req.body.telefono_contacto,
    instagram_contacto: req.body.instagram_contacto,
    productos_destacados: jsonArray(req.body.productos_destacados),
    patrones_destacados: jsonArray(req.body.patrones_destacados),
  };

  if (!existing) {
    db.prepare(`
      INSERT INTO catalog_settings (
        usuario_id, es_publico, nombre_negocio, email_contacto, telefono_contacto,
        instagram_contacto, productos_destacados, patrones_destacados,
        fecha_creacion, fecha_actualizacion
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      uid,
      data.es_publico ?? 0,
      data.nombre_negocio || '',
      data.email_contacto || '',
      data.telefono_contacto || '',
      data.instagram_contacto || '',
      data.productos_destacados || '[]',
      data.patrones_destacados || '[]',
      now, now,
    );
  } else {
    const fields = [];
    const values = [];
    for (const [k, v] of Object.entries(data)) {
      if (v !== undefined) {
        fields.push(`${k} = ?`);
        values.push(v);
      }
    }
    fields.push('fecha_actualizacion = ?');
    values.push(now);
    values.push(uid);

    db.prepare(`UPDATE catalog_settings SET ${fields.join(', ')} WHERE usuario_id = ?`).run(...values);
  }

  const row = db.prepare('SELECT * FROM catalog_settings WHERE usuario_id = ?').get(uid);
  res.json(row);
});

module.exports = router;
