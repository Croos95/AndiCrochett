# Sprint 1 · Justificación de diseño

## Paleta de colores
Definida en [`lib/core/constants/colors.dart`](../../lib/core/constants/colors.dart) (constante `AppColors`).

### Decisiones
- **Verde oliva** como color primario: evoca lo artesanal, natural, cercano al estambre. Aleja el branding de los azules corporativos genéricos.
- **Resaltado complementario**: aplicado a acciones secundarias para evitar canibalizar la atención al CTA principal.
- **Rojo error**: usado *solo* para acciones destructivas y mensajes de error — no decorativo.

Los colores viven en una sola constante para garantizar consistencia entre pantallas y permitir refactor centralizado.

## Tipografía
**Lora** — serif moderna, con 8 variantes (Regular, Italic, Medium, SemiBold, Bold + sus itálicas).

### Por qué Lora
- Estética que combina **artesanal con legible**.
- Buena legibilidad en pantalla.
- Múltiples pesos → permite jerarquizar sin cambiar de familia.
- Open Source (SIL Open Font License) — sin issues de licenciamiento.

Configurada en [`pubspec.yaml`](../../pubspec.yaml) y aplicada vía [`lib/core/config/theme.dart`](../../lib/core/config/theme.dart).

## Sistema de espaciado
[`lib/core/constants/sizes.dart`](../../lib/core/constants/sizes.dart) define una escala consistente:
- `xs`, `sm`, `md`, `lg`, `xl` para padding/margin.
- `radiusSm`, `radiusMd`, `radiusLg` para esquinas redondeadas.
- `fontSizeSm`, `fontSizeMd`, `fontSizeLg` para tamaños de texto.
- `buttonHeightSm/Md/Lg` para alturas de botón.

Esto evita números mágicos sueltos (`padding: 12`, `padding: 14`, `padding: 16`) que aparecen cuando cada developer decide el valor en el momento. El resultado: ritmo visual estable a lo largo de la app.

## Componentes reutilizables
Cada widget reutilizable encapsula decisiones de diseño que no deben re-tomarse en cada call site:

| Componente | Encapsula |
|---|---|
| `AppButton.primary` | Color primario + texto blanco + radio + altura estándar |
| `AppButton.secondary` | Color complementario, mismo radio/altura |
| `AppButton.danger` | Color error, para acciones destructivas |
| `AppButton.outlined` | Borde, transparente, para acciones terciarias |
| `CustomInput` | Borde + label flotante + estados focus/error consistentes |
| `EmptyStateView` | Ilustración + texto + CTA cuando no hay datos |

El estado `isLoading` del botón es particularmente importante: al disparar acciones async, el botón se transforma en spinner y bloquea taps adicionales — previene doble submit sin que cada formulario tenga que implementarlo.

## Layout responsive
[`AppLayout`](../../lib/core/widgets/app_layout.dart) ajusta:
- **Desktop**: sidebar permanente a la izquierda + contenido principal a la derecha.
- **Móvil**: sidebar como drawer, contenido full-width.

La transición ocurre alrededor del breakpoint 720px (acorde a Material 3).

## Decisión clave: offline-first
La UX está diseñada asumiendo que **todos los CRUDs pegan a SQLite local**, no a la red. Esto significa:
- Acciones instantáneas (sin spinners largos).
- Sin estado de "sincronizando".
- La app sirve aún en zonas sin conexión (la dueña del negocio sale a entregar pedidos sin wifi).

La sincronización con la nube queda como background opcional, no como bloqueador de UI.
