# Estructura del Proyecto

## 📁 Organización General

```
lib/
├── core/                # Elementos globales reutilizables
├── services/            # Servicios transversales
├── utils/               # Funciones auxiliares
├── widgets/             # Componentes reutilizables globales
├── features/            # Arquitectura modular por funcionalidad
├── shared/              # Elementos compartidos entre features
└── l10n/                # Internacionalización
```

## 🔧 Core

Configuraciones centrales del sistema.

- **routes.dart** → Definición de rutas y navegación
- **theme.dart** → Tema global (colores, tipografías)
- **env.dart** → Variables de entorno (API base URL, flags)
- **constants/** → Colores, textos, tamaños y espaciados

## 🛠️ Services

- Autenticación
- Comunicación con API
- Persistencia local

## 📚 Utils & Widgets

- Validadores de formularios
- Helpers generales
- Botones personalizados, inputs, layout base

## 🎯 Features (Módulos Independientes)

### auth/
Acceso seguro al sistema
- Modelos de usuario
- Repositorio de autenticación
- Página de login

### dashboard/
Pantalla principal tras iniciar sesión
- Resumen de inventario
- Pedidos próximos
- Accesos rápidos

### inventory/
Gestión de productos e insumos
- Crear, editar, eliminar productos
- Control de stock
- Alertas de bajo inventario

### agenda/
Gestión de pedidos y citas
- Crear pedidos
- Asignar fechas
- Visualización tipo calendario

### patterns/
Editor de patrones de crochet (módulo principal)
- Crear y editar patrones
- Canvas de diseño
- Guardar y exportar

### landing_connection/ (Opcional)
- Compartir patrones/productos
- Conexión con landing pública

## 📦 Estructura de Features

Cada feature sigue esta estructura:

```
feature/
├── data/           # Modelos y repositorios
├── presentation/   # UI y gestor de estado
└── providers/      # Estado (Provider)
```

## 🌍 l10n

- Español
- Inglés (opcional)

## ✅ Tests

```
test/
├── unit/           # Lógica y servicios
└── widget/         # Componentes UI
```

## 🏗️ Arquitectura

- **Modular**: Separación por features
- **Escalable**: Cada módulo es independiente
- **Mantenible**: Separación clara de responsabilidades (Data, Presentation, Core)
