// functions/test/auth.test.js
//
// Tests del middleware de autenticación usando node:test (built-in en Node 18+).
// Inyectamos un verificador mock para no depender de Firebase real.

const test = require("node:test");
const assert = require("node:assert/strict");
const express = require("express");

const { authenticate } = require("../middleware/auth");

/** Crea una app Express mínima con la ruta /me protegida por authenticate. */
function buildApp(verifyIdToken) {
  const app = express();
  const router = express.Router();
  router.use(authenticate({ verifyIdToken }));
  router.get("/me", (req, res) => res.status(200).json({ user: req.user }));
  app.use("/secure", router);
  return app;
}

/** Hace una request manual contra una app Express sin levantar servidor. */
function call(app, { path, headers = {} }) {
  return new Promise((resolve) => {
    const req = Object.assign(Object.create(express.request), {
      method: "GET",
      url: path,
      headers,
      app,
      // express.request.get usa headers internamente
    });

    const res = Object.assign(Object.create(express.response), {
      app,
      statusCode: 200,
      _headers: {},
      _body: undefined,
      setHeader() { return this; },
      getHeader() { return undefined; },
      removeHeader() { return this; },
      set() { return this; },
      status(code) { this.statusCode = code; return this; },
      json(payload) { this._body = payload; this.end(); },
      end() { resolve({ status: this.statusCode, body: this._body }); },
    });

    app.handle(req, res);
  });
}

test("rechaza request sin header Authorization", async () => {
  const app = buildApp(async () => { throw new Error("should not be called"); });
  const r = await call(app, { path: "/secure/me", headers: {} });
  assert.equal(r.status, 401);
  assert.equal(r.body.error, "missing_bearer_token");
});

test("rechaza header sin prefijo Bearer", async () => {
  const app = buildApp(async () => { throw new Error("should not be called"); });
  const r = await call(app, {
    path: "/secure/me",
    headers: { authorization: "abc.def.ghi" },
  });
  assert.equal(r.status, 401);
  assert.equal(r.body.error, "missing_bearer_token");
});

test("rechaza Bearer vacío", async () => {
  const app = buildApp(async () => { throw new Error("should not be called"); });
  const r = await call(app, {
    path: "/secure/me",
    headers: { authorization: "Bearer " },
  });
  assert.equal(r.status, 401);
  assert.equal(r.body.error, "empty_bearer_token");
});

test("rechaza cuando el verificador lanza", async () => {
  const app = buildApp(async () => {
    const e = new Error("expired");
    e.code = "auth/id-token-expired";
    throw e;
  });
  const r = await call(app, {
    path: "/secure/me",
    headers: { authorization: "Bearer fake.token" },
  });
  assert.equal(r.status, 401);
  assert.equal(r.body.error, "invalid_token");
  assert.equal(r.body.code, "auth/id-token-expired");
});

test("acepta token válido y adjunta req.user", async () => {
  const app = buildApp(async (token) => {
    assert.equal(token, "valid.token");
    return {
      uid: "u-123",
      email: "test@example.com",
      email_verified: true,
      auth_time: 1700000000,
    };
  });
  const r = await call(app, {
    path: "/secure/me",
    headers: { authorization: "Bearer valid.token" },
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.user.uid, "u-123");
  assert.equal(r.body.user.email, "test@example.com");
  assert.equal(r.body.user.emailVerified, true);
});
