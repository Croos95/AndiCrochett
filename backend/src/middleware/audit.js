// Middleware que persiste cada request HTTP en `audit_log`. Alimenta el
// dashboard de seguridad: cuántas llamadas, qué endpoints, qué errores,
// quién las hizo (cuando hay auth).

const db = require('../db');

// Endpoints que NO conviene auditar (ruido sin valor analítico).
const SKIP_PATHS = new Set([
  '/health',
  '/api/security/login-attempt', // se audita por su propia vía como login_attempt
]);

const insertAudit = db.prepare(`
  INSERT INTO audit_log (
    event_type, usuario_id, email, method, path, status_code,
    success, ip_address, user_agent, error_message, duration_ms
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`);

function auditMiddleware(req, res, next) {
  if (SKIP_PATHS.has(req.path)) return next();

  const start = Date.now();

  res.on('finish', () => {
    try {
      const duration = Date.now() - start;
      const success = res.statusCode >= 200 && res.statusCode < 400 ? 1 : 0;
      // `req.user` se setea en verifyFirebaseToken; puede estar undefined
      // si la ruta es pública o si la autenticación falló.
      const usuarioId = req.user ? req.user.uid : null;
      insertAudit.run(
        'api_call',
        usuarioId,
        null,                         // email no aplica en api_call
        req.method,
        req.originalUrl.split('?')[0],
        res.statusCode,
        success,
        req.ip || null,
        (req.headers['user-agent'] || '').slice(0, 200),
        null,                         // error_message: solo lo usamos en login_attempt
        duration,
      );
    } catch (err) {
      // Auditoría nunca debe tumbar la request.
      // eslint-disable-next-line no-console
      console.error('[audit] no se pudo persistir api_call:', err.message);
    }
  });

  next();
}

/** Registra un intento de login (success o fail). Lo llaman las rutas de seguridad. */
function recordLoginAttempt({ email, success, errorMessage, ip, userAgent }) {
  insertAudit.run(
    'login_attempt',
    null,
    email || null,
    null,
    null,
    null,
    success ? 1 : 0,
    ip || null,
    (userAgent || '').slice(0, 200),
    errorMessage || null,
    null,
  );
}

module.exports = { auditMiddleware, recordLoginAttempt };
