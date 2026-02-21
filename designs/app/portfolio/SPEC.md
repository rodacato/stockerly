# Portfolio — Spec

> **Zona:** app
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/portfolio` |
| **Layout** | `app` |
| **Controlador** | `PortfoliosController#show` |
| **Vista principal** | `app/views/portfolios/show.html.erb` |
| **Fase** | Fase 3 |

---

## Diseno de referencia

- **Captura:** screen.png
- **HTML Stitch:** code.html
- **Variantes:** screen-multidivisa.png + code-multidivisa.html (posiciones en diferentes divisas con tasas FX)

---

## Secciones y elementos

### 1. KPI Cards (3 tarjetas)

| Tarjeta | Descripcion |
|---------|-------------|
| **Total Value** | Valor total del portafolio |
| **Unrealized Gain** | Ganancia/perdida no realizada con porcentaje |
| **Buying Power** | Poder de compra disponible |

### 2. Donut Chart (Allocation by Sector)

- Grafico donut de asignacion por sector usando `conic-gradient` CSS
- Muestra porcentaje por sector (Technology, Healthcare, Finance, etc.)
- Partial: `_allocation_sidebar.html.erb`

### 3. Tabs (Open Positions / Closed Positions / Dividend History)

- Tres pestanas para alternar entre vistas
- Tab activo resaltado visualmente

### 4. Positions Table

- Tabla con las posiciones del portafolio
- Columnas: Ticker, Name, Shares, Avg Cost, Current Price, P&L, P&L %, Sparkline
- Sparklines SVG inline para mini-graficos de tendencia
- Partial: `_positions_table.html.erb`

---

## Datos necesarios

Datos hardcodeados (Fase 3). Modelos futuros listados:

| Modelo | Uso |
|--------|-----|
| `Portfolio` | Contenedor principal del portafolio del usuario |
| `Position` | Posiciones abiertas y cerradas |
| `Trade` | Trades para calcular `avg_cost` |
| `Asset` | Datos del activo (ticker, nombre, precio) |
| `DividendPayment` | Historial de dividendos recibidos |
| `FxRate` | Tasas de cambio para conversion multi-divisa |

---

## Formularios y acciones

No hay formularios en esta pagina. Es una vista de solo lectura.

Acciones futuras (Fase 6+): Registrar trade, cerrar posicion.

---

## Stimulus controllers

| Controller | Archivo | Uso |
|------------|---------|-----|
| `tabs` | `tabs_controller.js` | Tabs de posiciones (Open/Closed/Dividends) |

Pendiente en fases futuras: controlador para el donut chart interactivo.

---

## Turbo

No hay Turbo Frames implementados actualmente. En fases futuras:

- Turbo Frame para la tabla de posiciones (cambiar tab sin recarga completa)

---

## Empty states

| Seccion | Mensaje |
|---------|---------|
| Open Positions | "No positions yet -- Record your first investment" |
| Closed Positions | "No closed positions yet" |
| Dividend History | "Dividends will appear here when received" |

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

- `avg_cost` se calcula a partir de los Trades asociados a cada Position.
- Multi-currency: la variante multidivisa muestra posiciones en diferentes divisas con conversion via `FxRate`.
- Partials: `_positions_table`, `_allocation_sidebar`.
- El controlador hereda de `AuthenticatedController` (requiere login).
- Usa `resource :portfolio` (singular) en routes porque cada usuario tiene un unico portafolio.
