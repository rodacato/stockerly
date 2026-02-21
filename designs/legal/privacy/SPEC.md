# Privacy Policy — Spec

> **Zona:** Legal
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/privacy` |
| **Layout** | `legal` |
| **Controlador** | `LegalController#privacy` |
| **Vista principal** | `app/views/legal/privacy.html.erb` |
| **Fase** | 1 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`
- **Variantes:** Ninguna

---

## Secciones y elementos

- **Breadcrumbs:** Navegacion de migas de pan (Home > Privacy Policy).
- **TOC sidebar (sticky):** Tabla de contenidos lateral fija que permite navegar entre secciones.
- **7 content sections:**
  1. Introduction
  2. Collection (que datos se recopilan)
  3. Usage (como se usan los datos)
  4. Storage (donde y como se almacenan)
  5. Rights (derechos del usuario sobre sus datos)
  6. Cookies (politica de cookies)
  7. Contact (informacion de contacto para consultas de privacidad)
- **Back to Top button:** Boton flotante para volver al inicio de la pagina.

---

## Datos necesarios

Datos hardcodeados. Contenido legal estatico.

---

## Formularios y acciones

Ninguno

---

## Stimulus controllers

Ninguno identificado

---

## Turbo

No aplica

---

## Empty state

No aplica

---

## Estado de implementacion

| Etapa | Estado |
|-------|--------|
| Diseno (Stitch) | Completo |
| HTML estatico | Completo |
| Backend conectado | No requerido |
| Tests | No requerido (pagina estatica) |

---

## Notas

- Fase 1 completa. Contenido legal estatico.
- Usa el layout `legal` que provee estructura de 2 columnas con TOC lateral sticky.
- El TOC sidebar usa scroll-spy para resaltar la seccion actualmente visible.
