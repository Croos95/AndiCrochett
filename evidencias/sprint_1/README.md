# Sprint 1 — UX/UI

## Descripción del sprint
Sprint inaugural enfocado en investigación de usuarios y diseño de interfaz. Se entregó un **prototipo navegable** con justificación de diseño, evaluado por dos usuarios de perfiles complementarios (dueña del negocio + perfil creativo externo).

## Objetivo
Cumplir las leyes UI/UX:
- Jerarquía visual clara.
- Consistencia de paleta y tipografía.
- Navegación predecible.
- Densidad de información apropiada para el flujo de la microempresa.

## Tecnologías utilizadas
- **Flutter Material 3** — `MaterialApp.router` con `go_router`.
- **Tipografía Lora** — incluida en `assets/fonts/`, declarada en [`pubspec.yaml`](../../pubspec.yaml).
- **Paleta AppColors** — [`lib/core/constants/colors.dart`](../../lib/core/constants/colors.dart) (verde oliva como acento de marca, resaltado complementario, error rojo).
- **Sistema de espaciado y tamaños** — [`lib/core/constants/sizes.dart`](../../lib/core/constants/sizes.dart) con escalas `sm/md/lg/xl`.
- **Widgets reutilizables**:
  - [`AppButton`](../../lib/core/widgets/custom_button.dart) con 4 variantes (`primary`, `secondary`, `danger`, `outlined`) + estado `isLoading`.
  - [`CustomInput`](../../lib/core/widgets/custom_input.dart).
  - [`AppLayout`](../../lib/core/widgets/app_layout.dart) — chrome compartido con sidebar.
  - [`Sidebar`](../../lib/core/widgets/sidebar.dart) — navegación entre secciones.
  - [`CardContextMenu`](../../lib/core/widgets/card_context_menu.dart) — acciones por card.
  - [`EmptyStateView`](../../lib/core/widgets/empty_state_view.dart) — placeholder consistente cuando hay 0 resultados.

## Resultado del testing de usabilidad
Resumen documentado en [`documentation/ux-testing-video.txt`](../../documentation/ux-testing-video.txt). Dos participantes, dos perspectivas:

### Dueña del negocio (usuaria real)
- Aceptación positiva del flujo general.
- Aprobó paleta + tipografía.
- Le pareció intuitiva la distribución de elementos.
- Considera la app útil para gestionar su microempresa.

### Invitado externo (perfil creativo)
- Mirada más crítica → identificó aspectos mejorables de UI/UX.
- Recomendaciones para navegación más fluida.
- Insumo valioso para refinar diseño.

Video de la sesión: [`https://youtu.be/k0iLwJATY8Q`](https://youtu.be/k0iLwJATY8Q).

## Prototipo desplegado
La app navegable está disponible en producción:
- **URL**: [`https://andicrochett-bcb21.web.app/`](https://andicrochett-bcb21.web.app/)
- Login con email/password o Google Sign-In.
- Secciones: Dashboard, Inventario, Agenda, Diseños, Patrones, Catálogo público.

## Documentación detallada
1. [Justificación de diseño](01-justificacion-diseno.md)
2. [Leyes UI/UX aplicadas](02-leyes-uiux.md)
3. [Resultados del testing](03-testing-usuarios.md)

## Documento original entregado
El PDF original del Sprint 1 vive en [`documentation/Sprint-1 AndiCrochett.pdf`](../../documentation/Sprint-1%20AndiCrochett.pdf).

## Criterios cumplidos
| Criterio del PDF | Entregado |
|---|---|
| Prototipo navegable | App web desplegada en `andicrochett-bcb21.web.app` |
| Justificación de diseño | [01-justificacion-diseno.md](01-justificacion-diseno.md) + paleta/tipografía documentadas |
| Cumple leyes UX/UI | [02-leyes-uiux.md](02-leyes-uiux.md) lista cada ley + dónde se aplica |
