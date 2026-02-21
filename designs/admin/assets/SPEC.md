# Admin: Asset Management — Spec

> **Zona:** admin
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/admin/assets` |
| **Layout** | `admin` |
| **Controlador** | `Admin::AssetsController#index` |
| **Vista principal** | `app/views/admin/assets/index.html.erb` |
| **Fase** | Fase 4 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`

---

## Secciones y elementos

- **3 KPI cards:**
  1. **Total Assets** — Cantidad total de activos registrados en el sistema.
  2. **Syncing** — Activos actualmente en proceso de sincronizacion con fuentes de datos.
  3. **Alerts** — Numero de alertas activas asociadas a activos.

- **Tabs de filtro:**
  - All — Muestra todos los activos.
  - Stocks — Filtra solo acciones.
  - Crypto — Filtra solo criptomonedas.

- **Asset table:**
  - Columnas: Name, Symbol, Source, Status, Actions.
  - **Name:** Nombre completo del activo con icono/logo.
  - **Symbol:** Ticker del activo (ej. AAPL, BTC).
  - **Source:** Fuente de datos (Polygon.io, CoinGecko, etc.).
  - **Status:** Badge indicando estado (active/inactive/syncing).
  - **Actions:** Boton edit (editar configuracion), toggle (activar/desactivar).

- **Pagination:** Navegacion por paginas debajo de la tabla.

---

## Datos necesarios

Datos hardcodeados (Fase 4). Modelos futuros listados.

- `Asset` — Activos financieros (name, symbol, asset_type, source, status).
- `SystemLog` — Logs de sincronizacion asociados a activos.

---

## Formularios y acciones

- **PATCH** `/admin/assets/:id` — Actualizar estado del activo (active/inactive).
- **Toggle switch** — Cambio rapido de estado via PATCH con Turbo Stream.

---

## Stimulus controllers

- `tab-controller` — Alternar entre tabs All/Stocks/Crypto, filtrando la tabla.
- `toggle-controller` — Toggle de estado del activo (active/inactive) con feedback visual.

---

## Turbo

- Turbo Frame para la tabla de assets, permitiendo filtrado por tabs sin recarga completa.
- Turbo Stream para actualizar el status badge tras toggle sin recargar la fila.

---

## Empty state

"No assets found — Add your first asset or run initial sync."

Icono: `inventory_2`. Boton CTA: "Add Asset" o "Run Sync".

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

- Partials: `_assets_table` para la tabla de activos (reutilizable con filtros).
- El toggle de status publica un evento `AssetStatusChanged` en el EventBus.
- Todas las acciones de admin generan un registro en `AuditLog` para trazabilidad.
- La paginacion usa parametros `page` y `per_page` (25 items por defecto).
