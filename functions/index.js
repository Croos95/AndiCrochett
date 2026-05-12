const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const { authenticate } = require("./middleware/auth");

const app = express();

const allowedOrigins = (process.env.ALLOWED_ORIGINS || "https://andicrochett-bcb21.web.app,http://localhost:5000")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

const corsOptions = {
  origin: (origin, callback) => {
    // Allow non-browser requests and same-origin server-to-server calls.
    if (!origin) {
      callback(null, true);
      return;
    }

    if (allowedOrigins.includes(origin)) {
      callback(null, true);
      return;
    }

    callback(new Error("Origin not allowed by CORS policy"));
  },
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
  exposedHeaders: ["Content-Length"],
  credentials: false,
  maxAge: 86400,
};

app.disable("x-powered-by");
app.use(helmet());
app.use(cors(corsOptions));
app.options("*", cors(corsOptions));
app.use(express.json({ limit: "1mb" }));

app.use((req, res, next) => {
  res.set("Cache-Control", "no-store");
  next();
});

// ── Rutas públicas ──────────────────────────────────────────────────────────

app.get("/health", (req, res) => {
  res.status(200).json({
    ok: true,
    service: "andicrochett-api",
    timestamp: new Date().toISOString(),
  });
});

// ── Rutas protegidas (requieren Firebase ID token) ──────────────────────────
//
// El middleware `authenticate()` exige `Authorization: Bearer <token>` con
// un ID token válido emitido por Firebase Auth del proyecto.
// Si el token falta, expira o es inválido devuelve 401 con detalle.

const secure = express.Router();
secure.use(authenticate());

secure.get("/me", (req, res) => {
  // El middleware adjuntó `req.user` con uid/email/emailVerified/authTime.
  res.status(200).json({ user: req.user });
});

secure.get("/ping", (req, res) => {
  res.status(200).json({ ok: true, uid: req.user.uid });
});

app.use("/secure", secure);

// ── Manejo de errores ───────────────────────────────────────────────────────

app.use((err, req, res, next) => {
  if (err && err.message && err.message.includes("CORS")) {
    logger.warn("Blocked by CORS", { origin: req.headers.origin || "unknown" });
    res.status(403).json({ error: "CORS blocked" });
    return;
  }

  logger.error("Unhandled error", err);
  res.status(500).json({ error: "Internal server error" });
});

exports.api = onRequest(
  {
    region: "us-central1",
    cors: false,
    invoker: "public",
  },
  app,
);

// Export para pruebas — permite hacer supertest contra `app` sin levantar
// Cloud Functions.
module.exports.app = app;
