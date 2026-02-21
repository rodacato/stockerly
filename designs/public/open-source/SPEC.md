# Open Source Project — Spec

> **Zona:** Publica
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/open-source` |
| **Layout** | `public` |
| **Controlador** | `PagesController#open_source` |
| **Vista principal** | `app/views/pages/open_source.html.erb` |
| **Fase** | 1 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`
- **Variantes:** Ninguna

---

## Secciones y elementos

- **Hero:** Titulo y descripcion del proyecto open source, CTA hacia el repositorio.
- **Terminal mockup:** Simulacion visual de una terminal mostrando comandos de instalacion/setup del proyecto.
- **Why OSS section:** Seccion explicando por que Stockerly es open source y los beneficios.
- **Contributing guide:** Guia resumida de como contribuir al proyecto (pasos, guidelines).
- **Hall of Fame:** Reconocimiento a contribuidores destacados.

---

## Datos necesarios

Datos hardcodeados. Pagina de marketing estatica orientada a desarrolladores.

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

- Fase 1 completa. Pagina diferida de prioridad — es marketing orientado a desarrolladores.
- Stockerly es 100% open source, sin tiers de pricing ni funcionalidad premium.
- El Hall of Fame podria conectarse a la API de GitHub en el futuro para datos dinamicos de contribuidores.
