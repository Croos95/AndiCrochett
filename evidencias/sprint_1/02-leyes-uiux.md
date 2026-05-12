# Sprint 1 · Leyes UI/UX aplicadas

El PDF pide cumplir con "las leyes UI/UX". Este doc lista las principales y muestra cómo aterrizaron en la app.

## Ley de Hick (decisiones rápidas)
> *El tiempo de decisión crece con el número y complejidad de opciones.*

**Aplicación**: el sidebar muestra solo 5–6 secciones de primer nivel (Dashboard, Inventario, Agenda, Diseños, Patrones, Catálogo). Acciones secundarias se agrupan en menús contextuales (`CardContextMenu`), no en la nav principal.

## Ley de Fitts (tamaño y distancia)
> *El tiempo para alcanzar un objetivo depende de su tamaño y distancia.*

**Aplicación**:
- Los botones tienen altura mínima `Sizes.buttonHeightMd` (~40px) — cómoda para clic y touch.
- Los CTAs primarios viven en lugares predecibles (esquina inferior derecha en formularios, header en listados).

## Ley de Jakob (familiaridad)
> *Los usuarios prefieren que tu sitio funcione como los demás que ya conocen.*

**Aplicación**:
- Login con email/password + Google: patrón estándar de SaaS.
- Sidebar a la izquierda en desktop, drawer en móvil — el patrón Material 3 que el usuario ya conoce.
- Tabla → card → detalle: navegación clásica de admin panels.

## Ley de Miller (chunking)
> *La memoria de trabajo soporta ~7 elementos a la vez.*

**Aplicación**: las listas de productos/pedidos están paginadas o virtualizadas. Los formularios largos se dividen en secciones agrupadas visualmente.

## Ley de proximidad (Gestalt)
> *Elementos cercanos se perciben como un grupo.*

**Aplicación**: en cards de producto y pedido, los campos relacionados (nombre + categoría, total + estado) se agrupan con espaciado interno menor que el espaciado entre cards.

## Ley de la similitud (Gestalt)
> *Elementos parecidos se perciben como funcionalmente iguales.*

**Aplicación**: todos los CTAs primarios son verde oliva, todos los destructivos son rojo, todos los outlined tienen el mismo borde. El usuario aprende el código de color una vez y lo extrapola al resto de la app.

## Ley de Doherty (feedback inmediato)
> *La productividad crece con respuestas del sistema en < 400ms.*

**Aplicación**:
- Todas las acciones de CRUD pegan a SQLite local → respuesta instantánea.
- Los botones con acción async muestran spinner inmediatamente (`isLoading`).
- Las validaciones de inputs se ejecutan en tiempo real, no solo al submit.

## Ley de Tesler (complejidad inherente)
> *Toda app tiene una cantidad mínima de complejidad. Si el diseñador no la asume, la asume el usuario.*

**Aplicación**: ejemplo del patrón de crochet. La sintaxis (`R1: 6pb (6)`, bloques `[..]xN`) es compleja por naturaleza. En lugar de exponer un editor visual aún más complejo, se entregó:
- Sintaxis textual concisa que el usuario aprende una vez.
- Un parser que tolera variantes (`r` minúscula, total opcional, espacios flexibles).
- Errores con mensajes en español específicos por causa (línea vacía, falta `:`, bloques anidados, etc.).

La complejidad la absorbe el sistema (parser), no el usuario.

## Estado vacío
`EmptyStateView` aparece consistentemente cuando una lista está vacía: ilustración + texto explicativo + CTA principal. Nunca se muestra una lista en blanco sin contexto.

## Consistencia de error
Todos los errores se muestran:
- En **inputs**: borde rojo + texto debajo en `AppColors.error`.
- En **acciones**: `SnackBar` con fondo rojo, ícono `error_outline`, texto blanco.
- En **vistas**: Card con texto rojo, sin tumbar la página.

El usuario nunca se queda preguntando si algo falló o no.
