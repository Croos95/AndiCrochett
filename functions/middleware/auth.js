// functions/middleware/auth.js
//
// Middleware Express que valida un Firebase ID token (JWT) emitido por
// Firebase Auth. El cliente lo obtiene con `user.getIdToken()` y lo envía
// como `Authorization: Bearer <token>` en cada request a rutas protegidas.
//
// Por qué Firebase ID token y no un JWT propio:
//   - Ya hay Firebase Auth wired en la app Flutter.
//   - Firebase rota claves, expira tokens (1h) y los revoca en logout.
//   - Cero infraestructura de keystore propia.

const admin = require("firebase-admin");

// Inicializa Admin SDK con la cuenta de servicio default del entorno de
// Cloud Functions (en local emulador, ADC). Solo una vez por proceso.
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Builder del middleware. Acepta opciones para inyectar un verificador
 * en pruebas (evita levantar Firebase real).
 *
 * @param {object} [opts]
 * @param {(token: string) => Promise<object>} [opts.verifyIdToken] - función
 *   que recibe el token y devuelve el claims decoded. Default: Firebase Admin.
 */
function authenticate(opts = {}) {
  const verify = opts.verifyIdToken
    || ((token) => admin.auth().verifyIdToken(token));

  return async (req, res, next) => {
    const header = req.get("Authorization") || "";

    if (!header.startsWith("Bearer ")) {
      return res.status(401).json({
        error: "missing_bearer_token",
        message: "Falta el header Authorization: Bearer <token>",
      });
    }

    const token = header.slice("Bearer ".length).trim();
    if (!token) {
      return res.status(401).json({
        error: "empty_bearer_token",
        message: "El token Bearer viene vacío",
      });
    }

    try {
      const decoded = await verify(token);
      // Adjunta el usuario decoded a req para que los handlers lo usen.
      req.user = {
        uid: decoded.uid,
        email: decoded.email,
        emailVerified: decoded.email_verified === true,
        authTime: decoded.auth_time,
      };
      next();
    } catch (err) {
      const code = err && err.code ? err.code : "auth/invalid-token";
      return res.status(401).json({
        error: "invalid_token",
        code,
        message: "El token no es válido o expiró",
      });
    }
  };
}

module.exports = { authenticate };
