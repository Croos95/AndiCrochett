# Sprint 5 · Análisis de resultados

Este documento explica **cómo leer cada métrica del dashboard** y qué decisión de negocio dispara. Es la "guía de interpretación" para la dueña del producto.

## KPI 1 · Productos
**Qué mide:** el tamaño del catálogo activo.

**Cómo leerlo:** crecer este número sin crecer "Pedidos totales" sugiere que se está invirtiendo en variedad sin pedirla la demanda — riesgo de capital inmovilizado.

**Decisión:** si el ratio `Pedidos / Productos` es < 1, congelar nuevas altas y enfocarse en mover stock.

## KPI 2 · Bajo stock
**Qué mide:** productos con `currentStock <= 5` (umbral en `InventoryRepository.updateProductStock`).

**Cómo leerlo:** es la lista de reabastecimiento pendiente.

**Decisión:** si > 20% del catálogo está en bajo stock, programar una jornada de producción ese fin de semana.

## KPI 3 · Sin existencias
**Qué mide:** productos con `currentStock <= 0`.

**Cómo leerlo:** son ventas perdidas hoy. Cada uno representa al menos una persona que entró al catálogo y no pudo comprar.

**Decisión:** priorizar producción inmediata sobre cualquier producto nuevo en cola.

## KPI 4 · Pedidos totales
**Qué mide:** todos los pedidos creados históricamente, sin importar estado.

**Cómo leerlo:** velocidad de crecimiento del negocio. Compararlo mensualmente.

**Decisión:** si crece < 5% mes/mes durante 3 meses seguidos, repensar canales de venta.

## KPI 5 · Clientes
**Qué mide:** clientes registrados en la base.

**Cómo leerlo:** ratio `Pedidos / Clientes` = pedidos por cliente. Si es ~1, hay un problema de retención.

**Decisión:** ratio > 2 → producto fuerte de recompra; lanzar programa de referidos. Ratio < 1 → enfocarse en post-venta.

## KPI 6 · Ingresos 30 días
**Qué mide:** `SUM(total)` de pedidos con `estado='completed'` y `fecha_pedido >= hoy - 30d`.

**Cómo leerlo:** la única métrica de **dinero realmente cobrado**. Los pedidos pendientes o en proceso no cuentan.

**Decisión:** caída > 20% respecto al período anterior → revisar canales y precios.

## Gráfico · Pedidos por estado
**Qué mide:** distribución actual de los pedidos según su estado de procesamiento.

**Patrones a buscar:**
- **Amarillo (pending) grande**: cuello de botella en aceptación. ¿Estás respondiendo rápido?
- **Azul (inProgress) grande y persistente**: producción atrasada. Más tiempo de manufactura del esperado.
- **Rojo (cancelled) > 10%**: o el precio espanta, o el tiempo de entrega comunicado no es realista.
- **Verde dominante**: salud operativa.

**Decisión:** identificar el "color que crece" mes a mes y atacar esa fase del funnel.

## Top productos
**Qué mide:** los 5 productos con más unidades vendidas históricamente.

**Cómo leerlo:**
- **Concentración**: si el top 5 = 80% de las ventas, eres dependiente de pocos productos. Riesgo si uno deja de vender.
- **Distribución pareja**: catálogo saludable, varios "caballos de batalla".
- **Revenue vs unidades**: un producto con muchas unidades pero poco revenue es un "abridor"; uno con pocas unidades y mucho revenue es un "premium".

**Decisión:** asegurar **stock permanente** del top 3. Considerar variantes (color, talla) del producto #1.

## Lo que **no** mide el dashboard hoy
Estos están fuera de alcance del Sprint 5 pero son extensiones naturales:

- **Tasa de cancelación temporal** (cancelled / total por mes).
- **Tiempo promedio pending → completed** (lead time de producción).
- **Distribución horaria de pedidos** (¿cuándo compra la gente?).
- **Productos creados pero nunca vendidos** (catálogo muerto).

Todos se pueden derivar de las tablas existentes (`pedidos`, `items_pedido`, `productos`) — solo falta agregar las queries al `AnalyticsRepository` y un widget más.

## Eventos vs. dashboard
El dashboard refleja datos **almacenados** (SQLite). Los **eventos** (`AnalyticsEvent`) capturan **acciones** del usuario. La combinación da:

| Pregunta | Fuente |
|---|---|
| ¿Cuánto vendí? | Dashboard (`Ingresos 30 días`) |
| ¿Cuántas veces buscaron productos? | Eventos (`product_searched`) |
| ¿Cuántos clientes tengo? | Dashboard |
| ¿Cuántos abandonaron el registro? | Eventos (`sign_up_success` vs página vista) |
| ¿Cuál es mi producto más vendido? | Dashboard (`Top productos`) |
| ¿Cuál es la más buscada? | Eventos (cuando se hookee `productSearched`) |

Cuando se conecte Firebase Analytics (ver [02-integracion-analytics.md](02-integracion-analytics.md)), la pestaña de eventos del panel de Firebase responderá las preguntas de la columna derecha automáticamente.
