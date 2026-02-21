# Earnings Calendar — Spec

> **Zona:** app
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/earnings` |
| **Layout** | `app` |
| **Controlador** | `EarningsController#index` |
| **Vista principal** | `app/views/earnings/index.html.erb` |
| **Fase** | Fase 3 |

---

## Diseno de referencia

- **Captura:** screen.png
- **HTML Stitch:** code.html
- **Variantes:** Ninguna

---

## Secciones y elementos

### 1. Toggle My Watchlist / All Markets

- Toggle para filtrar entre earnings de la watchlist del usuario o todos los mercados
- Cambia el contenido del calendario y la barra lateral

### 2. Month Navigator

- Navegacion por mes (boton prev/next)
- Muestra el mes y ano actual seleccionado
- Permite recorrer meses anteriores y futuros

### 3. Watchlist Priority (sidebar)

- Lista de los 5 proximos eventos de earnings de activos en la watchlist del usuario
- Muestra: ticker, fecha, horario (BMO/AMC)
- Partial: `_watchlist_priority.html.erb`

### 4. Calendar Grid

- Grilla de 7 columnas (Lun-Dom)
- Celdas con eventos de earnings
- Cada evento muestra: ticker, badge BMO/AMC
- BMO = Before Market Open, AMC = After Market Close
- Partial: `_calendar_grid.html.erb`

### 5. Earnings Pro Tips Card

- Tarjeta informativa con consejos sobre earnings
- Contenido estatico educativo
- Partial: `_pro_tips.html.erb`

### 6. Legend

- Leyenda explicando los badges y colores del calendario
- BMO badge, AMC badge, watchlist highlight

---

## Datos necesarios

Datos hardcodeados (Fase 3). Modelos futuros listados:

| Modelo | Uso |
|--------|-----|
| `EarningsEvent` | Eventos de earnings (ticker, fecha, horario BMO/AMC, estimaciones) |
| `Asset` | Datos del activo asociado al evento |
| `WatchlistItem` | Para filtrar y priorizar earnings de la watchlist |

---

## Formularios y acciones

No hay formularios en esta pagina. Es una vista de solo lectura.

La navegacion por mes se maneja con links GET (e.g., `/earnings?month=2026-03`).

---

## Stimulus controllers

| Controller | Archivo | Uso |
|------------|---------|-----|
| `calendar-nav` | `calendar_nav_controller.js` | Navegacion por mes (prev/next) |
| `toggle` | `toggle_controller.js` | Toggle watchlist/all markets |

---

## Turbo

No hay Turbo Frames implementados actualmente. En fases futuras:

- Turbo Frame para la grilla del calendario (cambiar de mes sin recarga completa)

---

## Empty states

| Seccion | Mensaje |
|---------|---------|
| Watchlist Priority | "Follow stocks to track their earnings" |
| Calendar (mes vacio) | "No earnings reports this month" |

---

## Estado de implementacion

| Etapa | Estado |
|-------|--------|
| Diseno (Stitch) | Completo |
| HTML estatico | Completo |
| Backend conectado | Pendiente (Fase 6) |
| Tests | Pendiente |

---

## Notas

- BMO = Before Market Open, AMC = After Market Close. Son badges visuales en las celdas del calendario.
- Partials: `_calendar_grid`, `_watchlist_priority`, `_pro_tips`.
- El controlador hereda de `AuthenticatedController` (requiere login).
- La navegacion de mes usa el Stimulus controller `calendar-nav` (no `calendar`).
- En el futuro, la grilla se actualizara via Turbo Frame al cambiar de mes.
