const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
  || path.join(__dirname, '..', 'firebase-service-account.json');

if (!admin.apps.length) {
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } else {
    console.warn(
      `[auth] Service account no encontrado en ${serviceAccountPath}. ` +
      `Las rutas protegidas rechazarán todas las peticiones hasta configurarlo.`
    );
  }
}

async function verifyFirebaseToken(req, res, next) {
  const header = req.headers.authorization || '';
  const match = header.match(/^Bearer (.+)$/);

  if (!match) {
    return res.status(401).json({ error: 'Token de autorización faltante' });
  }

  // Bypass para tests: cualquier token "test-..." se acepta y se decodifica
  // como un usuario sintético. Solo activo cuando NODE_ENV=test.
  if (process.env.NODE_ENV === 'test' && match[1].startsWith('test-')) {
    req.user = {
      uid: match[1].slice('test-'.length) || 'test-user',
      email: 'test@example.com',
      emailVerified: true,
    };
    return next();
  }

  if (!admin.apps.length) {
    return res.status(500).json({ error: 'Backend sin credenciales de Firebase' });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(match[1]);
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      emailVerified: decoded.email_verified,
    };
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Token inválido o expirado' });
  }
}

module.exports = { verifyFirebaseToken };
