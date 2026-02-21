# Profile — Spec

> **Zona:** app
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/profile` (GET / PATCH) |
| **Layout** | `app` |
| **Controlador** | `ProfilesController#show, #update` |
| **Vista principal** | `app/views/profiles/show.html.erb` |
| **Fase** | Fase 3 |

---

## Diseno de referencia

- **Captura:** screen.png
- **HTML Stitch:** code.html
- **Variantes:** Ninguna

---

## Secciones y elementos

### 1. Profile Header

- Avatar del usuario (iniciales o imagen)
- Nombre completo
- Badges (e.g., "Verified")
- Partial: `_profile_header.html.erb`

### 2. Personal Information Form

- Formulario editable con datos personales del usuario
- Campos: nombre, email, telefono, divisa preferida (`preferred_currency`)
- Partial: `_personal_info_form.html.erb`

### 3. Account Settings

- Toggles de configuracion de cuenta
- Opciones: Notifications, Privacy, Two-Factor Authentication
- Cada toggle controla una preferencia booleana
- Partial: `_account_settings.html.erb`

### 4. Watchlist Table

- Tabla con los activos en la watchlist del usuario
- Columnas: Ticker, Name, Price, Change, Actions
- Partial: `_watchlist_table.html.erb`

---

## Datos necesarios

Datos hardcodeados (Fase 3). Modelos futuros listados:

| Modelo | Uso |
|--------|-----|
| `User` | Datos personales (nombre, email, telefono, preferencias) |
| `WatchlistItem` | Items de la watchlist del usuario |
| `Asset` | Datos del activo (ticker, nombre, precio) |

---

## Formularios y acciones

### Update Profile

| Campo | Tipo | Metodo |
|-------|------|--------|
| Name | text input | PATCH `/profile` |
| Email | email input | PATCH `/profile` |
| Phone | tel input | PATCH `/profile` |
| Preferred Currency | select (USD/EUR/MXN) | PATCH `/profile` |

Nota: En Fase 3 el update redirige a `/profile` con mensaje flash "Profile updated (demo mode)."

### Account Settings Toggles

- Los toggles de Notifications, Privacy y Two-Factor se envian como parte del PATCH del perfil o como acciones independientes en fases futuras.

---

## Stimulus controllers

| Controller | Archivo | Uso |
|------------|---------|-----|
| `toggle` | `toggle_controller.js` | Switches de account settings (Notifications, Privacy, Two-Factor) |
| `flash` | `flash_controller.js` | Auto-dismiss de notificaciones flash tras update |

---

## Turbo

No hay Turbo Frames implementados actualmente. En fases futuras:

- Turbo Frame para la tabla de watchlist (eliminar items sin recarga)

---

## Empty states

| Seccion | Mensaje |
|---------|---------|
| Watchlist vacia | "Start following stocks from the Market Explorer" |

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

- Partials: `_profile_header`, `_personal_info_form`, `_account_settings`, `_watchlist_table`.
- El controlador hereda de `AuthenticatedController` (requiere login).
- Usa `resource :profile` (singular) en routes porque cada usuario tiene un unico perfil.
- Cambio de password es una accion separada (no incluida en este formulario).
- Las acciones `show` y `update` ya estan implementadas; `update` redirige con mensaje demo.
