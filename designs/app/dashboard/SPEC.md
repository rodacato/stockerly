# Dashboard Principal — Spec

> **Zona:** app
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/dashboard` |
| **Layout** | `app` |
| **Controlador** | `DashboardController#show` |
| **Vista principal** | `app/views/dashboard/show.html.erb` |
| **Fase** | Fase 3 |

---

## Diseno de referencia

- **Captura:** screen.png
- **HTML Stitch:** code.html
- **Variantes:** screen-multidivisa.png + code-multidivisa.html (misma vista con selector de divisa USD/EUR/MXN)

---

## Secciones y elementos

### 1. KPI Stat Cards (4 tarjetas)

| Tarjeta | Descripcion |
|---------|-------------|
| **Total Balance** | Valor total del portafolio del usuario |
| **Day Gain/Loss** | Ganancia o perdida del dia con porcentaje |
| **Buying Power** | Poder de compra disponible |
| **Market Sentiment** | Sentimiento del mercado derivado de TrendScores promedio de la watchlist del usuario |

### 2. Watchlist Performance

- Tabla con las posiciones de la watchlist del usuario
- Columnas: Ticker, Name, Price, Change, Change %, Trend Score
- Tabs para filtrar (e.g., All, Stocks, Crypto)
- Partial: `_watchlist_table.html.erb`

### 3. Relevant News Feed

- 3 tarjetas de noticias relevantes a los activos seguidos
- Cada tarjeta: titulo, fuente, timestamp, resumen
- Partial: `_news_feed.html.erb`

### 4. Trending Today (sidebar)

- Lista de activos con mayor movimiento del dia
- Muestra ticker, precio y cambio porcentual
- Partial: `_trending_today.html.erb`

### 5. Weekly Insight Card

- Tarjeta con resumen semanal del mercado
- Texto informativo con datos clave
- Partial: `_weekly_insight.html.erb`

### 6. Market Status Indicator

- Indicador de estado del mercado (Open/Closed/Pre-Market/After-Hours)
- Badge visual con color segun estado
- Partial: `_market_status.html.erb`

---

## Datos necesarios

Datos hardcodeados (Fase 3). Modelos futuros listados:

| Modelo | Uso |
|--------|-----|
| `Portfolio` | Balance total, buying power |
| `Position` | Posiciones para calcular ganancias |
| `Asset` | Ticker, nombre, precio actual |
| `WatchlistItem` | Items de la watchlist del usuario |
| `NewsArticle` | Noticias relevantes |
| `TrendScore` | Calculo de Market Sentiment |

---

## Formularios y acciones

No hay formularios en esta pagina. Es una vista de solo lectura.

---

## Stimulus controllers

| Controller | Archivo | Uso |
|------------|---------|-----|
| `tabs` | `tabs_controller.js` | Tabs de la watchlist (All, Stocks, Crypto) |
| `flash` | `flash_controller.js` | Auto-dismiss de notificaciones flash |

---

## Turbo

No hay Turbo Frames implementados actualmente. En fases futuras:

- Turbo Frame para la tabla de watchlist (actualizar sin recarga completa)
- Turbo Stream potencial para Market Status (actualizacion en tiempo real)

---

## Empty states

| Seccion | Mensaje |
|---------|---------|
| Watchlist vacia | "Add your first stock to watchlist" |
| News vacio | "Follow stocks to see relevant news" |

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

- Market Sentiment se deriva del promedio de TrendScores de la watchlist del usuario.
- Multi-currency se controla via parametro `currency` (USD/EUR/MXN). La variante multidivisa muestra la misma vista con conversiones de divisa.
- Partials: `_watchlist_table`, `_news_feed`, `_trending_today`, `_weekly_insight`, `_market_status`.
- El controlador hereda de `AuthenticatedController` (requiere login).
