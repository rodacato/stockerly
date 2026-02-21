# Empty States Collection — Spec

> **Zona:** shared
> **Estado:** design

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | N/A — Componentes embebidos en paginas existentes |
| **Layout** | Varios (`app`, segun la pagina contenedora) |
| **Controlador** | N/A — Renderizado como partial desde cualquier controlador |
| **Vista principal** | `app/views/components/_empty_state.html.erb` |
| **Fase** | Fase 3 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`

---

## Secciones y elementos

Partial reutilizable `_empty_state.html.erb` con los siguientes parametros:

| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| `icon` | String | Nombre del icono Material Symbols Rounded |
| `title` | String | Titulo principal del empty state |
| `description` | String | Descripcion secundaria explicativa |
| `cta_text` | String (opcional) | Texto del boton de accion |
| `cta_path` | String (opcional) | Ruta del boton de accion |

### 6 empty states definidos:

1. **Watchlist Empty** (Dashboard, Profile)
   - Icono: `visibility`
   - Titulo: "Your watchlist is empty"
   - Descripcion: "Start tracking stocks and crypto by adding them to your watchlist."
   - CTA: "Explore Markets" -> `/market`

2. **Portfolio Empty** (Portfolio)
   - Icono: `account_balance_wallet`
   - Titulo: "No positions yet"
   - Descripcion: "Add your first position to start tracking your portfolio performance."
   - CTA: "Add Position" -> `/portfolio/new` (TBD)

3. **Alerts Empty** (Alerts)
   - Icono: `notifications_none`
   - Titulo: "No alerts configured"
   - Descripcion: "Set up price alerts to get notified when stocks hit your target prices."
   - CTA: "Create Alert" -> `/alerts/new` (TBD)

4. **Earnings Empty** (Earnings)
   - Icono: `event_note`
   - Titulo: "No upcoming earnings"
   - Descripcion: "Add stocks to your watchlist to see their upcoming earnings dates."
   - CTA: "Add to Watchlist" -> `/market`

5. **News Empty** (Dashboard news section)
   - Icono: `article`
   - Titulo: "No relevant news"
   - Descripcion: "News articles related to your watchlist will appear here."
   - CTA: "Explore Markets" -> `/market`

6. **Live Alert Feed Empty** (Dashboard live feed)
   - Icono: `radio_button_checked`
   - Titulo: "No alerts triggered"
   - Descripcion: "When your alert conditions are met, notifications will appear here in real-time."
   - CTA: Ninguno

---

## Datos necesarios

Ninguno — Los empty states se renderizan cuando no hay datos. La logica de mostrar/ocultar reside en la vista contenedora.

---

## Formularios y acciones

Ninguno — Los CTAs son links de navegacion, no formularios.

---

## Stimulus controllers

Ninguno — Componente puramente presentacional.

---

## Turbo

No aplica directamente. Los empty states se reemplazan via Turbo Stream/Frame cuando se agregan datos (ej. al agregar un item al watchlist, el empty state desaparece y se muestra la lista).

---

## Empty state

N/A — Este ES el componente de empty state.

---

## Estado de implementacion

| Etapa | Estado |
|-------|--------|
| Diseno (Stitch) | Completo |
| HTML estatico | Pendiente |
| Backend conectado | Pendiente |
| Tests | Pendiente |

---

## Notas

- Critico segun los expertos de Product y UX. Cada empty state funciona como un mini-onboarding, guiando al usuario hacia la siguiente accion.
- El partial debe ser flexible: si no se pasa `cta_text`/`cta_path`, no se renderiza el boton (caso Live Alert Feed).
- Estructura visual sugerida: centrado vertical y horizontal, icono grande (48px), titulo en `text-lg font-semibold`, descripcion en `text-sm text-gray-500`, boton primario estandar.
- Debe implementarse en Fase 3 para que todas las paginas autenticadas tengan empty states desde el inicio.
- Considerar animacion sutil (fade-in) al cargar el empty state.
