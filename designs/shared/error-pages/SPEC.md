# Error Pages (404/500) — Spec

> **Zona:** shared
> **Estado:** design

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | N/A — Servidas por Rails/web server en errores HTTP |
| **Layout** | Ninguno — HTML standalone en `public/` |
| **Controlador** | N/A — Servidas directamente por el servidor |
| **Vista principal** | `public/404.html`, `public/500.html` |
| **Fase** | Fase 4+ |

---

## Diseno de referencia

- **Capturas:** `screen-404.png`, `screen-500.png`
- **HTML Stitch:** `code-404.html`, `code-500.html`

---

## Secciones y elementos

### Pagina 404 — Not Found

- **Codigo grande:** "404" en texto extra-large (`text-8xl` o similar), color primario `#004a99`.
- **Icono:** `search_off` (Material Symbols Rounded), tamano grande (64px), color gris.
- **Titulo:** "Page Not Found"
- **Descripcion:** "The page you're looking for doesn't exist or has been moved."
- **Botones:**
  - "Go to Dashboard" (primario) -> `/dashboard`
  - "Go Home" (secundario/outline) -> `/`

### Pagina 500 — Server Error

- **Codigo grande:** "500" en texto extra-large (`text-8xl` o similar), color rojo.
- **Icono:** `cloud_off` (Material Symbols Rounded), tamano grande (64px), color gris.
- **Titulo:** "Something Went Wrong"
- **Descripcion:** "We're experiencing technical difficulties. Please try again in a few moments."
- **Botones:**
  - "Try Again" (primario) -> `javascript:location.reload()` o pagina anterior.
  - "Go Home" (secundario/outline) -> `/`

### Elementos comunes

- Logo de Stockerly centrado en la parte superior.
- Contenido centrado vertical y horizontalmente en la pagina.
- Fondo blanco limpio, sin navegacion ni footer (paginas independientes).
- Fuente Inter (cargada desde Google Fonts inline o embebida).
- Iconos Material Symbols Rounded (cargados inline o embebidos).
- Responsive: adaptado a movil con tamaños reducidos.

---

## Datos necesarios

Ninguno — Paginas estaticas HTML puro. No requieren acceso a base de datos ni modelos.

---

## Formularios y acciones

Ninguno

---

## Stimulus controllers

Ninguno — HTML estatico puro, sin JavaScript framework. Todo el CSS/JS necesario esta inline o embebido en el archivo HTML.

---

## Turbo

No aplica — Paginas standalone fuera del framework de la aplicacion.

---

## Empty state

No aplica

---

## Estado de implementacion

| Etapa | Estado |
|-------|--------|
| Diseno (Stitch) | Completo |
| HTML estatico | Pendiente |
| Backend conectado | No requerido |
| Tests | No requerido (paginas estaticas) |

---

## Notas

- Segun el UX expert, implementacion diferida a post-Fase 4. Usar las paginas de error por defecto de Rails hasta entonces.
- Cuando se implementen, crear `public/404.html` y `public/500.html` con branding de Stockerly.
- Estas paginas deben ser completamente autocontenidas (CSS inline, fuentes embebidas o CDN), ya que se sirven cuando la aplicacion puede estar caida (especialmente 500).
- No depender de assets compilados por el asset pipeline, ya que podrian no estar disponibles en un error 500.
- Rails configura automaticamente `config.exceptions_app` para servir estas paginas. Verificar que `public/404.html` y `public/500.html` son detectados correctamente.
- Considerar agregar `public/422.html` para errores de validacion CSRF si es necesario.
