# Landing Page — Spec

> **Zona:** Publica
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/` |
| **Layout** | `public` |
| **Controlador** | `PagesController#landing` |
| **Vista principal** | `app/views/pages/landing.html.erb` |
| **Fase** | 1 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`
- **Variantes:** Ninguna

---

## Secciones y elementos

- **Hero:** Titulo principal, subtitulo descriptivo, boton CTA primario ("Get Started" o similar)
- **Features grid:** 6 tarjetas con icono + titulo + descripcion, cada una representando una funcionalidad clave de Stockerly
- **Stats bar:** Barra horizontal con metricas destacadas (numero de activos, usuarios, etc.)
- **How it works:** Seccion paso a paso explicando el flujo de uso de la plataforma
- **Final CTA:** Llamada a la accion de cierre con boton de registro
- **Footer:** Links de navegacion, legal, redes sociales

---

## Datos necesarios

Datos hardcodeados. Pagina de marketing estatica, no requiere modelos ni consultas a base de datos.

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

- Fase 1 completa. Pagina puramente estatica de marketing.
- No requiere conexion a backend ni datos dinamicos.
- El CTA principal redirige a `/register`.
