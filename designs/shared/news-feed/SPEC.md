# News Feed Page — Spec

> **Zona:** shared
> **Estado:** design

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/news` (TBD) |
| **Layout** | `app` |
| **Controlador** | `NewsController` (nuevo, TBD) |
| **Vista principal** | `app/views/news/index.html.erb` |
| **Fase** | Fase 6 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`

---

## Secciones y elementos

- **Search bar + filter chips:**
  - Input de busqueda por texto libre.
  - Filter chips por ticker (ej. AAPL, TSLA, BTC). Clickeables para activar/desactivar filtro.

- **Source filter dropdown:**
  - Filtro por fuente de noticias: All, Bloomberg, Reuters, WSJ, CNBC.

- **Time filter:**
  - Selector de rango temporal: Today, This Week, This Month, All Time.

- **Featured article (hero):**
  - Articulo destacado a ancho completo con imagen grande, titular, fuente, resumen y timestamp.
  - Ocupa el ancho completo del contenido principal.

- **2-column grid de news cards:**
  - Cada card incluye:
    - **Thumbnail** — Imagen del articulo (placeholder si no disponible).
    - **Source** — Nombre de la fuente con icono.
    - **Title** — Titular del articulo (max 2 lineas, truncado).
    - **Summary** — Resumen breve (max 3 lineas, truncado).
    - **Ticker badges** — Badges de los tickers mencionados en el articulo.
    - **Time** — Tiempo relativo de publicacion ("2h ago", "Yesterday").

- **Right sidebar:**
  - **"Trending Topics"** — Tags de temas trending clickeables (ej. "AI", "Earnings", "Fed").
  - **"From Your Watchlist"** — Mini-lista de noticias recientes de activos en el watchlist del usuario.

- **"Load More" button:**
  - Boton al final del grid para cargar mas articulos (paginacion infinita).

---

## Datos necesarios

- `NewsArticle` — Modelo con campos:
  - `title` — Titular del articulo.
  - `summary` — Resumen corto.
  - `url` — URL externa al articulo original.
  - `source` — Fuente (Bloomberg, Reuters, WSJ, CNBC, etc.).
  - `image_url` — URL de la imagen/thumbnail.
  - `published_at` — Fecha de publicacion.
  - `tickers` — Array de tickers mencionados (o relacion many-to-many con Asset).

---

## Formularios y acciones

- **GET** `/news` — Listado con parametros de filtro (search, source, time_range, tickers).
- **GET** `/news?page=N` — Paginacion para "Load More".

---

## Stimulus controllers

- `filter-controller` — Gestiona filtros de busqueda, fuente, tiempo y tickers. Envia parametros al servidor al cambiar filtros.
- `infinite-scroll-controller` — Detecta click en "Load More" y appenda nuevos articulos al grid sin recargar la pagina.

---

## Turbo

- Turbo Frame para el grid de articulos, permitiendo filtrado y paginacion parcial.
- Turbo Frame individual para el sidebar (actualizable independientemente).

---

## Empty state

Icono: `article`. Titulo: "No news articles found." Descripcion: "Try adjusting your filters or check back later for the latest market news." CTA: "Clear Filters."

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

- Segun el Product expert, los traders necesitan un feed de noticias filtrable. Actualmente las noticias solo aparecen en el Dashboard (3 items).
- La pagina `/news` es una expansion del widget de noticias del Dashboard.
- Las noticias se obtienen de APIs externas (TBD). En Fase 4 se usan datos hardcodeados/seed.
- El featured article se selecciona como el mas reciente o el de mayor relevancia (algoritmo TBD).
- "From Your Watchlist" en el sidebar requiere la relacion entre NewsArticle y los tickers del watchlist del usuario.
- Los links de articulos abren en nueva pestana (`target="_blank" rel="noopener"`).
- Considerar cache de noticias para evitar llamadas excesivas a APIs externas.
