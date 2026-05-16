# Sprint 5 · Análisis de resultados

Este documento explica **cómo leer cada métrica del dashboard** y qué decisión dispara. Es la "guía de interpretación" para la dueña del producto.

El dashboard tiene dos pestañas:

- **[Negocio](#sección-1--negocio)** — operación: catálogo, inventario, ventas, clientes.
- **[Seguridad](#sección-2--seguridad-ciberseguridad)** — salud de la plataforma: intentos de login, llamadas a la API, errores.

---

## Sección 1 · Negocio

### KPI 1 · Productos
**Qué mide:** el tamaño del catálogo activo.

**Cómo leerlo:** crecer este número sin crecer "Pedidos totales" sugiere que se está invirtiendo en variedad sin pedirla la demanda — riesgo de capital inmovilizado.

**Decisión:** si el ratio `Pedidos / Productos` es < 1, congelar nuevas altas y enfocarse en mover stock.

### KPI 2 · Bajo stock
**Qué mide:** productos con `currentStock <= 5` (umbral calculado server-side en `backend/src/routes/products.js`).

**Cómo leerlo:** es la lista de reabastecimiento pendiente.

**Decisión:** si > 20% del catálogo está en bajo stock, programar una jornada de producción ese fin de semana.

### KPI 3 · Sin existencias
**Qué mide:** productos con `currentStock <= 0`.

**Cómo leerlo:** son ventas perdidas hoy. Cada uno representa al menos una persona que entró al catálogo y no pudo comprar.

**Decisión:** priorizar producción inmediata sobre cualquier producto nuevo en cola.

### KPI 4 · Pedidos totales
**Qué mide:** todos los pedidos creados históricamente, sin importar estado.

**Cómo leerlo:** velocidad de crecimiento del negocio. Compararlo mensualmente.

**Decisión:** si crece < 5% mes/mes durante 3 meses seguidos, repensar canales de venta.

### KPI 5 · Clientes
**Qué mide:** clientes registrados en la base.

**Cómo leerlo:** ratio `Pedidos / Clientes` = pedidos por cliente. Si es ~1, hay un problema de retención.

**Decisión:** ratio > 2 → producto fuerte de recompra; lanzar programa de referidos. Ratio < 1 → enfocarse en post-venta.

### KPI 6 · Ingresos 30 días
**Qué mide:** `SUM(total)` de pedidos con `estado='completed'` y `fecha_pedido >= hoy - 30d`.

**Cómo leerlo:** la única métrica de **dinero realmente cobrado**. Los pedidos pendientes o en proceso no cuentan.

**Decisión:** caída > 20% respecto al período anterior → revisar canales y precios.

### Gráfico · Pedidos por estado
**Qué mide:** distribución actual de los pedidos según su estado de procesamiento.

**Patrones a buscar:**
- **Amarillo (pending) grande**: cuello de botella en aceptación. ¿Estás respondiendo rápido?
- **Azul (inProgress) grande y persistente**: producción atrasada. Más tiempo de manufactura del esperado.
- **Rojo (cancelled) > 10%**: o el precio espanta, o el tiempo de entrega comunicado no es realista.
- **Verde dominante**: salud operativa.

**Decisión:** identificar el "color que crece" mes a mes y atacar esa fase del funnel.

### Top productos
**Qué mide:** los 5 productos con más unidades vendidas históricamente.

**Cómo leerlo:**
- **Concentración**: si el top 5 = 80% de las ventas, eres dependiente de pocos productos. Riesgo si uno deja de vender.
- **Distribución pareja**: catálogo saludable, varios "caballos de batalla".
- **Revenue vs unidades**: un producto con muchas unidades pero poco revenue es un "abridor"; uno con pocas unidades y mucho revenue es un "premium".

**Decisión:** asegurar **stock permanente** del top 3. Considerar variantes (color, talla) del producto #1.

### Productos por reabastecer (nuevo)
**Qué mide:** los hasta 10 productos con menor stock, priorizados rojo (`out_of_stock`) sobre amarillo (`low_stock`), y dentro de cada grupo por cantidad ascendente.

**Cómo leerlo:** lista directa de compra para el siguiente pedido al proveedor. Cada item muestra `#id` para que sea inmediato buscarlo en la planilla externa.

**Decisión:**
- Los rojos van al pedido **hoy**, no mañana.
- Los amarillos van en la lista de cosas "a comprar el próximo viaje al proveedor" — comprar antes de que se vuelvan rojos.
- Si la lista tiene > 10 items consistentemente, el umbral de `low_stock` (≤ 5) es muy alto para tu rotación; baja a 3.

---

## Sección 2 · Seguridad (ciberseguridad)

Esta pestaña responde a la pregunta operativa: **¿qué le está pasando a mi plataforma?** Datos derivados del `audit_log` del backend — toda request HTTP y todo intento de login quedan registrados.

### Intentos de login (últimos 7 días)

**Qué muestra:** total, exitosos, fallidos, tasa de éxito (%).

**Cómo leerlo:**
- **Tasa de éxito < 70%** → algo está mal: o los usuarios no recuerdan su contraseña (UX de reset débil) o estás bajo intento de fuerza bruta.
- **Picos abruptos de "Fallidos"** sin equivalente en "Exitosos" → posible ataque automatizado contra una cuenta.
- **Tasa de éxito ~100% pero pocos intentos totales** → el sistema lo usa solo una persona; no preocuparse.

**Decisión:**
- Si la tasa de éxito cae > 20 puntos en una semana → habilitar 2FA para esa cuenta y mandar email de "Detectamos actividad inusual".
- Si los fallidos vienen todos de la misma IP → bloquear la IP a nivel CDN/firewall y considerar agregar rate limit por IP (`express-rate-limit`) en el backend.

### Llamadas a la API (últimas 24 horas)

**Qué muestra:** total, exitosas (2xx-3xx), no autorizadas (401/403), errores 5xx, latencia promedio.

**Cómo leerlo:**

| Métrica | Lectura sana | Lectura preocupante |
|---|---|---|
| Total | crece con la actividad de la app | crece sin actividad → bots o cliente buggy en bucle |
| No autorizadas | 0–5% | > 10% → posible enumeración de endpoints (alguien testeando qué responde sin auth) |
| Errores 5xx | 0 idealmente | cualquier 5xx → revisar logs de inmediato |
| Latencia | < 50 ms (SQLite local es rápido) | > 200 ms → hay queries pesadas o el disco está saturado |

**Decisión:**
- 401/403 que aumentan → revisar si hay un cliente con token expirado en bucle (problema de refresh) o un atacante. El log de [`backend/src/middleware/audit.js`](../../backend/src/middleware/audit.js) tiene IP + user-agent para discriminar.
- 5xx → ir a la terminal del backend, buscar el stack trace de la hora indicada. Si el patrón es repetitivo, abrir issue.
- Latencia subiendo → considerar índices adicionales en SQLite o migrar a Postgres si crece la base.

### Endpoints más usados (24h)

**Qué muestra:** top 5 endpoints (método + path) por número de hits.

**Cómo leerlo:** te dice qué partes de la app son las más consumidas.
- Si `GET /api/designs` o `GET /api/products` lideran con muchos hits → el polling del cliente (cada 3s mientras una pantalla está abierta) está cumpliendo su rol.
- Si un endpoint inesperado lidera (ej. `POST /api/orders` con cientos de hits) → bug en el cliente o automatización maliciosa.

**Decisión:**
- Endpoints de lectura con tráfico extremo → considerar cachear con `Cache-Control` o subir el `pollInterval` en [`Env.pollInterval`](../../lib/core/config/env.dart).
- Endpoints de escritura con tráfico extremo → revisar quién está enviando y por qué.

### Logins fallidos recientes

**Qué muestra:** lista de hasta 10 intentos fallidos en los últimos 7 días, con email, código de error de Firebase (`wrong-password`, `user-not-found`, `too-many-requests`...), timestamp y IP.

**Cómo leerlo:**
- **Mismo email + muchos fallos** → ese usuario perdió su contraseña; enviarle un correo de reset proactivo.
- **Muchos emails distintos + misma IP** → ataque de "credential stuffing". Bloquear IP.
- **`user-not-found` repetidos** → alguien está enumerando emails para ver cuáles tienen cuenta. Lo correcto sería que el backend respondiera lo mismo para "cuenta inexistente" y "contraseña mala", pero Firebase Auth no lo permite a nivel SDK.

**Decisión:**
- `wrong-password` > 5 por email en 1h → bloqueo temporal de la cuenta.
- `too-many-requests` indica que Firebase ya activó su propio rate limit — bien, pero también validar el origen.

---

## Lo que **no** mide el dashboard hoy

Extensiones naturales que se pueden agregar sin cambiar la arquitectura:

**Negocio:**
- Tasa de cancelación temporal (cancelled / total por mes).
- Tiempo promedio pending → completed (lead time de producción).
- Distribución horaria de pedidos (¿cuándo compra la gente?).
- Productos creados pero nunca vendidos (catálogo muerto).

**Seguridad:**
- IP geolocalizada (con un servicio externo como ipapi.co).
- Detección de "actividad nueva" — un user_agent que nunca había visto.
- Alertas push: si el ratio de 401s > X% en 1 minuto, mandar Slack/email.

Todos se derivan de las tablas existentes (`pedidos`, `items_pedido`, `productos`, `audit_log`). Solo falta agregar las queries al backend y un widget más en cada pestaña.

## Eventos vs. dashboard vs. audit_log

El proyecto tiene tres canales de datos distintos. Cada uno responde un tipo de pregunta:

| Pregunta | Fuente | Dónde se ve |
|---|---|---|
| ¿Cuánto vendí este mes? | `pedidos` (SQLite) | Dashboard → Negocio → Ingresos 30 días |
| ¿Cuál es mi producto más vendido? | `items_pedido` (SQLite) | Dashboard → Negocio → Top productos |
| ¿Cuántos productos necesito reabastecer? | `productos` (SQLite) | Dashboard → Negocio → Productos por reabastecer |
| ¿Quién intentó hackearme hoy? | `audit_log` (SQLite) | Dashboard → Seguridad → Logins fallidos |
| ¿Cuántas requests recibió mi backend? | `audit_log` (SQLite) | Dashboard → Seguridad → Llamadas a la API |
| ¿Cuántas veces buscaron productos? | Firebase Analytics (`product_searched`) | Firebase Console |
| ¿Qué pantalla es la más visitada? | Firebase Analytics (`screen_view`) | Firebase Console |
| ¿Cuántos usuarios activos esta semana? | Firebase Analytics (DAU/WAU automáticos) | Firebase Console |

**Dashboard interno** = datos del taller (lo que pasó con tu inventario y plataforma).
**Firebase Analytics** = datos del producto (cómo usan tu app los usuarios).
Las dos son útiles, ninguna reemplaza a la otra.
