# Terms of Service — Spec

> **Zona:** Legal
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/terms` |
| **Layout** | `legal` |
| **Controlador** | `LegalController#terms` |
| **Vista principal** | `app/views/legal/terms.html.erb` |
| **Fase** | 1 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`
- **Variantes:** Ninguna

---

## Secciones y elementos

- **Breadcrumbs:** Navegacion de migas de pan (Home > Terms of Service).
- **TOC sidebar (sticky):** Tabla de contenidos lateral fija que permite navegar entre secciones.
- **TL;DR section:** Resumen ejecutivo de los terminos mas importantes en lenguaje simple.
- **7 content sections:** Secciones detalladas de los terminos de servicio (uso aceptable, propiedad intelectual, limitaciones de responsabilidad, etc.).
- **Accept/Decline buttons:** Botones de aceptar/rechazar los terminos.

---

## Datos necesarios

Datos hardcodeados. Contenido legal estatico.

---

## Formularios y acciones

Ninguno (los botones Accept/Decline son de presentacion, no envian formulario en esta pagina).

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
- La seccion TL;DR facilita la lectura rapida de los puntos clave.
- Los botones Accept/Decline son visuales; la aceptacion real de terminos ocurre en el flujo de registro.
