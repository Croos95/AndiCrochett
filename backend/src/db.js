const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

const dbPath = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'andicrochett.db');

fs.mkdirSync(path.dirname(dbPath), { recursive: true });

const db = new Database(dbPath);

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uid TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT DEFAULT '',
    photo_url TEXT DEFAULT '',
    auth_provider TEXT DEFAULT 'email',
    settings TEXT DEFAULT '{}',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS productos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL UNIQUE,
    descripcion TEXT DEFAULT '',
    precio REAL NOT NULL,
    imagen TEXT DEFAULT '',
    categoria TEXT DEFAULT '',
    color TEXT DEFAULT '',
    peso TEXT DEFAULT '',
    marca TEXT DEFAULT '',
    cantidad INTEGER DEFAULT 0,
    estado TEXT DEFAULT 'available',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS clientes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    email TEXT UNIQUE,
    telefono TEXT,
    direccion TEXT
  );

  CREATE TABLE IF NOT EXISTS pedidos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id TEXT NOT NULL,
    cliente_id INTEGER,
    nombre_cliente TEXT DEFAULT '',
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega TIMESTAMP,
    total REAL NOT NULL,
    estado TEXT DEFAULT 'pending',
    notas TEXT DEFAULT '',
    contacto_cliente TEXT DEFAULT '',
    items_json TEXT DEFAULT '[]',
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS items_pedido (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id INTEGER NOT NULL,
    producto_id INTEGER NOT NULL,
    nombre_producto TEXT NOT NULL,
    cantidad INTEGER NOT NULL,
    precio_unitario REAL NOT NULL,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id)
  );

  CREATE TABLE IF NOT EXISTS designs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    descripcion TEXT DEFAULT '',
    usuario_id TEXT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL,
    design_id INTEGER NOT NULL,
    dificultad TEXT DEFAULT 'beginner',
    material_sugerido TEXT DEFAULT '',
    tamano_gancho TEXT DEFAULT '',
    estado TEXT DEFAULT 'draft',
    texto_patron TEXT DEFAULT '',
    usuario_id TEXT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (design_id) REFERENCES designs(id) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS catalog_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id TEXT NOT NULL UNIQUE,
    es_publico INTEGER DEFAULT 0,
    nombre_negocio TEXT DEFAULT '',
    email_contacto TEXT DEFAULT '',
    telefono_contacto TEXT DEFAULT '',
    instagram_contacto TEXT DEFAULT '',
    productos_destacados TEXT DEFAULT '[]',
    patrones_destacados TEXT DEFAULT '[]',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Bitácora de seguridad: cada request a la API + cada intento de login.
  -- Alimenta la sección "Seguridad" del dashboard de analítica.
  CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_type TEXT NOT NULL,            -- 'api_call' | 'login_attempt'
    usuario_id TEXT,                     -- uid de Firebase si autenticado
    email TEXT,                          -- usado en login attempts
    method TEXT,                         -- HTTP method (api_call)
    path TEXT,                           -- HTTP path (api_call)
    status_code INTEGER,                 -- HTTP status (api_call) | 0/1 success (login_attempt)
    success INTEGER,                     -- 1 = éxito, 0 = fallo
    ip_address TEXT,
    user_agent TEXT,
    error_message TEXT,
    duration_ms INTEGER
  );

  CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_log(timestamp);
  CREATE INDEX IF NOT EXISTS idx_audit_event_type ON audit_log(event_type);
`);

module.exports = db;
