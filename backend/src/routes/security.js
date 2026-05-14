// Rutas relacionadas con seguridad. La única ruta pública es la de registrar
// intentos de login (necesaria porque un intento fallido NO tiene token).

const express = require('express');
const { recordLoginAttempt } = require('../middleware/audit');

const router = express.Router();

router.post('/login-attempt', (req, res) => {
  const { email, success, errorMessage } = req.body || {};
  recordLoginAttempt({
    email: typeof email === 'string' ? email : null,
    success: !!success,
    errorMessage: typeof errorMessage === 'string' ? errorMessage : null,
    ip: req.ip,
    userAgent: req.headers['user-agent'],
  });
  res.status(201).json({ recorded: true });
});

module.exports = router;
