# Global Search Dropdown — Spec

> **Zona:** shared
> **Estado:** design

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | N/A — Overlay dropdown desde la barra de busqueda en el navbar de `app` |
| **Layout** | `app` (componente dentro del navbar) |
| **Controlador** | `SearchController` (API endpoint para resultados, TBD) |
| **Vista principal** | `app/views/components/_global_search.html.erb` |
| **Fase** | Fase 6 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`

---

## Secciones y elementos

- **Expanded search input:**
  - Estado focused: borde azul (`border-blue-600`), sombra sutil.
  - Badge "Cmd+K" a la derecha del input como hint de atajo de teclado.
  - Icono de busqueda (`search`) a la izquierda.
  - Boton "X" para limpiar el input.

- **Results dropdown:** (ancho ~480px, max-height con scroll)
  - Agrupado en 3 secciones con headers:

  1. **"Stocks & Assets"** section:
     - Cada resultado muestra: ticker (bold), nombre completo, precio actual, cambio porcentual (verde/rojo).
     - Boton "+" para agregar directamente al watchlist.
     - Maximo 5 resultados visibles.

  2. **"News"** section:
     - Cada resultado muestra: titulo del articulo, fuente, tiempo relativo.
     - Maximo 3 resultados visibles.

  3. **"Quick Actions"** section:
     - Acciones contextuales basadas en el query:
       - "Create alert for [query]" -> `/alerts/new?ticker=[query]`
       - "View [query] in Market Explorer" -> `/market?search=[query]`

- **Keyboard navigation:**
  - Flechas arriba/abajo para navegar entre resultados.
  - Enter para seleccionar el resultado resaltado.
  - Escape para cerrar el dropdown.
  - Tab para moverse entre secciones.

- **Footer:**
  - Hints de navegacion: iconos de flechas "Navigate", Enter "Select", Esc "Close".

- **Empty state:**
  - Texto: "No results for '[query]'"
  - Sugerencia: "Try searching for a stock symbol or company name."

---

## Datos necesarios

- `Asset` — Busqueda por `name` y `symbol` usando ILIKE (sin ransack, scopes de ActiveRecord).
- `NewsArticle` — Busqueda por `title` usando ILIKE.

---

## Formularios y acciones

- **GET** `/search?q=...` — Endpoint API que retorna resultados agrupados (assets, news, actions).
- **POST** `/watchlist_items` — Agregar activo al watchlist desde el boton "+" en los resultados.

---

## Stimulus controllers

- `search-controller` — Gestiona:
  - Debounce de 300ms antes de enviar la busqueda al servidor.
  - Keyboard navigation (flechas, enter, escape).
  - Atajo `Cmd+K` / `Ctrl+K` para enfocar el input de busqueda.
  - Abrir/cerrar dropdown basado en el estado del input.
  - Cerrar al clickear fuera del componente.

---

## Turbo

- Turbo Frame para los resultados del dropdown, actualizado con cada busqueda.
- Alternativa: fetch directo con JavaScript para mayor velocidad de respuesta (evaluar segun latencia).

---

## Empty state

Texto: "No results for '[query]'. Try searching for a stock symbol or company name."

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

- Segun los expertos de Product y UX, la barra de busqueda ya es visible en todas las paginas autenticadas pero actualmente no es funcional.
- Al presionar Enter sin seleccionar un resultado, redirige a Market Explorer (`/market`) con el query como filtro de busqueda.
- La busqueda usa scopes de ActiveRecord con ILIKE, sin ransack (decision de arquitectura v1).
- El debounce de 300ms es critico para evitar llamadas excesivas al servidor.
- Considerar cache de resultados recientes por usuario para mejorar la experiencia.
- El boton "+" de watchlist usa Turbo Stream para dar feedback inmediato sin cerrar el dropdown.
- En dispositivos moviles, el dropdown se expande a ancho completo.
