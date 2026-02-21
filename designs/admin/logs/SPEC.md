# Admin: System Logs — Spec

> **Zona:** admin
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/admin/logs` |
| **Layout** | `admin` |
| **Controlador** | `Admin::LogsController#index` |
| **Vista principal** | `app/views/admin/logs/index.html.erb` |
| **Fase** | Fase 4 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`

---

## Secciones y elementos

- **Filter bar:**
  - **Search input** — Busqueda por texto en mensajes de log.
  - **Severity dropdown** — Filtro por nivel: All, Info, Warning, Error, Critical.
  - **Module dropdown** — Filtro por modulo del sistema (Market Data, Alerts, Auth, etc.).
  - **Time Range** — Selector de rango temporal (Last Hour, Today, Last 7 Days, Last 30 Days, Custom).

- **Log table:**
  - Columnas: Status badge, Task, Module, Timestamp, Duration, Action.
  - **Status badge** — Icono con color segun severidad.
  - **Task** — Descripcion breve de la tarea ejecutada.
  - **Module** — Modulo del sistema que genero el log.
  - **Timestamp** — Fecha y hora del evento.
  - **Duration** — Tiempo de ejecucion de la tarea.
  - **Action** — Boton "View Details" para expandir detalles del log.

- **4 Stats cards:**
  1. **Success Rate** — Porcentaje de tareas exitosas (con sparkline de tendencia).
  2. **Active Alerts** — Numero de alertas del sistema activas.
  3. **Avg Run Time** — Tiempo promedio de ejecucion de tareas.
  4. **Storage** — Uso de almacenamiento de logs.

- **Auto-refresh toggle** — Switch para activar/desactivar refresco automatico de la tabla.

- **Export CSV button** — Boton para descargar los logs filtrados en formato CSV.

---

## Datos necesarios

Datos hardcodeados (Fase 4). Modelos futuros listados.

- `SystemLog` — Logs del sistema (severity, module, task, message, duration, metadata, created_at).

---

## Formularios y acciones

- **GET** `/admin/logs` — Listado con parametros de filtro (severity, module, time_range, search).
- **GET** `/admin/logs.csv` — Exportacion CSV con los mismos filtros aplicados.

---

## Stimulus controllers

- `filter-controller` — Gestiona los filtros (search, severity, module, time range) y envia el formulario de busqueda al cambiar cualquier filtro.
- `auto-refresh-controller` — Polling periodico (cada 30 segundos) para refrescar la tabla de logs cuando esta activado el toggle.

---

## Turbo

- Turbo Frame para la tabla de logs, permitiendo filtrado y paginacion sin recarga completa.
- Turbo Frame para los stats cards, actualizados junto con la tabla al aplicar filtros.

---

## Empty state

No aplica — El sistema siempre genera logs. Si no hay logs que coincidan con los filtros, se muestra un mensaje inline: "No logs match your filters. Try adjusting your search criteria."

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

- Partials: `_log_filters` para la barra de filtros, `_logs_table` para la tabla de logs.
- Severity badges con colores codificados:
  - **info** — azul (`bg-blue-100 text-blue-700`)
  - **warning** — amarillo (`bg-yellow-100 text-yellow-700`)
  - **error** — rojo (`bg-red-100 text-red-700`)
  - **critical** — morado (`bg-purple-100 text-purple-700`)
- El auto-refresh solo se activa en la vista de logs, no persiste entre navegaciones.
- Export CSV respeta los filtros activos al momento de la descarga.
