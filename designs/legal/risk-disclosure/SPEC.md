# Risk Disclosure — Spec

> **Zona:** Legal
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/risk-disclosure` |
| **Layout** | `legal` |
| **Controlador** | `LegalController#risk_disclosure` |
| **Vista principal** | `app/views/legal/risk_disclosure.html.erb` |
| **Fase** | 1 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`
- **Variantes:** Ninguna

---

## Secciones y elementos

- **Breadcrumbs:** Navegacion de migas de pan (Home > Risk Disclosure).
- **TOC sidebar (sticky):** Tabla de contenidos lateral fija que permite navegar entre secciones.
- **5 content sections:** Secciones detalladas sobre riesgos de inversion (riesgo de mercado, volatilidad, perdida de capital, riesgos especificos de crypto, limitaciones de la plataforma).
- **Warning boxes:** Cajas de advertencia destacadas con iconografia para resaltar los riesgos mas criticos.
- **Accept/Decline buttons:** Botones de aceptar/rechazar la divulgacion de riesgos.

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
- Los warning boxes usan estilos de alerta para resaltar riesgos criticos (colores de advertencia, iconos).
- Los botones Accept/Decline son visuales; requeridos por compliance fintech pero no envian datos en esta pagina.
- Stockerly es una plataforma de analisis, no un broker — este disclaimer es importante para el marco regulatorio.
