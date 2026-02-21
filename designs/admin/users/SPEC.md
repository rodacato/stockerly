# Admin: Users & Integrations — Spec

> **Zona:** admin
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/admin/users` |
| **Layout** | `admin` |
| **Controlador** | `Admin::UsersController#index` |
| **Vista principal** | `app/views/admin/users/index.html.erb` |
| **Fase** | Fase 4 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`

---

## Secciones y elementos

- **User Management table:**
  - Columnas: Profile (avatar + name + email), Join Date, Status badge, Actions.
  - **Profile** — Avatar circular (iniciales si no hay imagen), nombre completo y email debajo.
  - **Join Date** — Fecha de registro formateada.
  - **Status badge** — Estado del usuario: active (verde), suspended (rojo), pending (amarillo).
  - **Actions** — Botones: suspend (para usuarios activos), activate (para usuarios suspendidos).
  - **Pagination** — Navegacion por paginas debajo de la tabla.

- **Market Data Connectivity section:**
  - **Integration cards** — Tarjetas para cada proveedor de datos configurado:
    - **Polygon.io** — Logo, API key enmascarada (`****...xxxx`), status (connected/disconnected), last sync timestamp.
    - **CoinGecko** — Logo, API key enmascarada, status, last sync timestamp.
  - Cada tarjeta tiene botones: "Reveal Key", "Test Connection", "Remove".
  - **"Add New Provider" card** — Tarjeta con icono `+` y texto, abre formulario para agregar nuevo proveedor.

---

## Datos necesarios

Datos hardcodeados (Fase 4). Modelos futuros listados.

- `User` — Usuarios del sistema (name, email, role, status, created_at).
- `Integration` — Proveedores de datos de mercado (provider_name, api_key_encrypted, status, last_synced_at).

---

## Formularios y acciones

- **PATCH** `/admin/users/:id` — Actualizar estado del usuario (suspend/activate).
- **POST** `/admin/integrations` — Agregar nuevo proveedor de datos.
- **PATCH** `/admin/integrations/:id` — Actualizar configuracion de integracion (API key, status).
- **DELETE** `/admin/integrations/:id` — Eliminar proveedor de datos.

---

## Stimulus controllers

- `toggle-controller` — Toggle de estado del usuario (suspend/activate) con confirmacion.
- `reveal-controller` — Revelar/ocultar API key enmascarada. Requiere confirmacion de password del admin antes de mostrar la clave completa.

---

## Turbo

- Turbo Frame para la tabla de usuarios, permitiendo paginacion sin recarga completa.
- Turbo Stream para actualizar el status badge del usuario tras suspend/activate.
- Turbo Frame para la seccion de integraciones, permitiendo agregar/editar/eliminar sin recarga.

---

## Empty state

- **Users table:** Siempre tiene datos (al menos el usuario admin actual). No requiere empty state.
- **Integrations:** "Add your first data provider to start syncing market data." Icono: `cloud_sync`. CTA: "Add Provider".

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

- Partials: `_users_table` para la tabla de usuarios, `_integrations` para la seccion de conectividad.
- Las integraciones se gestionan dentro de esta misma pagina, no tienen un controlador separado. Se manejan via `Admin::UsersController` o un concern dedicado.
- El reveal de API key requiere confirmacion de password del admin como medida de seguridad. Genera un registro en `AuditLog` con la accion `api_key_revealed`.
- Suspend/activate de usuarios tambien genera registro en `AuditLog`.
- No hay social auth en v1, solo email/password, por lo que la gestion de usuarios es straightforward.
