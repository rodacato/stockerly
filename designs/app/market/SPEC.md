# Market Explorer — Spec

> **Zona:** app
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/market` |
| **Layout** | `app` |
| **Controlador** | `MarketController#index` |
| **Vista principal** | `app/views/market/index.html.erb` |
| **Fase** | Fase 3 |

---

## Diseno de referencia

- **Captura:** screen.png
- **HTML Stitch:** code.html
- **Variantes:** Ninguna

---

## Secciones y elementos

### 1. Index Cards (4 tarjetas de indices)

| Indice | Descripcion |
|--------|-------------|
| **S&P 500** | Valor actual, cambio diario, porcentaje |
| **NASDAQ** | Valor actual, cambio diario, porcentaje |
| **DOW** | Valor actual, cambio diario, porcentaje |
| **FTSE** | Valor actual, cambio diario, porcentaje |

### 2. Advanced Filters

- Filtros avanzados para refinar la busqueda de activos
- Campos: Sector, Market Cap, Volatility, Trend Strength
- Busqueda por texto con debounce
- Partial: `_filters.html.erb`

### 3. Market Listings Table

- Tabla paginada de activos del mercado (4,821 resultados hardcodeados)
- Columnas: Ticker, Name, Price, Change, Change %, Volume, Market Cap, Trend Score
- Paginacion al pie de la tabla
- Partial: `_listings_table.html.erb`

### 4. Export CSV Button

- Boton para exportar los resultados filtrados a CSV
- Pendiente de implementacion funcional en fases futuras

### 5. Real-time Updates Toggle

- Toggle para activar/desactivar actualizaciones en tiempo real
- Visual only en Fase 3

---

## Datos necesarios

Datos hardcodeados (Fase 3). Modelos futuros listados:

| Modelo | Uso |
|--------|-----|
| `Asset` | Listado de activos (ticker, nombre, precio, volumen, market cap) |
| `MarketIndex` | Datos de indices (S&P 500, NASDAQ, DOW, FTSE) |
| `TrendScore` | Puntuacion de tendencia por activo |

---

## Formularios y acciones

### Filter Form

| Campo | Tipo | Metodo |
|-------|------|--------|
| Busqueda | text input | GET `/market` con query params |
| Sector | select/dropdown | GET `/market?sector=...` |
| Market Cap | select/dropdown | GET `/market?market_cap=...` |
| Volatility | select/dropdown | GET `/market?volatility=...` |
| Trend Strength | select/dropdown | GET `/market?trend_strength=...` |

Todos los filtros se envian como parametros GET para mantener URLs compartibles.

---

## Stimulus controllers

| Controller | Archivo | Uso |
|------------|---------|-----|
| `tabs` | `tabs_controller.js` | Tabs de categorias de mercado |

Pendiente en fases futuras: controlador de filtros con debounce para busqueda en tiempo real.

---

## Turbo

No hay Turbo Frames implementados actualmente. En fases futuras:

- Turbo Frame para la tabla de listings (filtrar/paginar sin recarga completa)

---

## Empty state

No aplica. El mercado siempre tiene datos disponibles.

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

- No usar `ransack` en v1 -- usar ActiveRecord scopes con ILIKE para busquedas y filtros.
- Partials: `_filters`, `_listings_table`.
- El controlador hereda de `AuthenticatedController` (requiere login).
- La paginacion se implementara con `pagy` o similar en Fase 6.
- Export CSV sera una accion `format.csv` en el controlador cuando se conecte al backend.
