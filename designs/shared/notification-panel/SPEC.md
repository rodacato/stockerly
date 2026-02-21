# Notification Panel — Spec

> **Zona:** shared
> **Estado:** design

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | N/A — Overlay dropdown desde el icono de campana en el navbar de `app` |
| **Layout** | `app` (componente dentro del navbar) |
| **Controlador** | `NotificationsController` (API para marcar como leidas) |
| **Vista principal** | `app/views/components/_notification_panel.html.erb` |
| **Fase** | Fase 6 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`

---

## Secciones y elementos

- **Header:**
  - Titulo "Notifications" alineado a la izquierda.
  - Badge con conteo de notificaciones no leidas (numero en circulo azul).
  - Link "Mark all as read" alineado a la derecha.

- **Notification list:** (maximo 10 items visibles, scroll interno si hay mas)
  - Cada notificacion incluye:
    - **Icono** segun tipo (ver tipos abajo).
    - **Titulo** — En negrita si no leida, peso normal si leida.
    - **Body** — Texto truncado a 2 lineas con ellipsis.
    - **Relative time** — "2 min ago", "1 hour ago", etc.
  - **Fondo:** Items no leidos con fondo azul claro (`bg-blue-50`), leidos con fondo blanco.

- **4 tipos de notificacion:**
  1. `alert_triggered` — Icono: `notification_important`, color: naranja.
  2. `earnings_reminder` — Icono: `event`, color: azul.
  3. `system` — Icono: `info`, color: gris.
  4. `promotion` — Icono: `campaign`, color: verde.

- **Footer:**
  - Link "View All Notifications" que dirige a una pagina completa de notificaciones (TBD).

- **Empty state:**
  - Icono: `notifications_none`
  - Texto: "No notifications yet"
  - Sin CTA.

---

## Datos necesarios

- `Notification` — Modelo con campos:
  - `user_id` — Referencia al usuario.
  - `title` — Titulo de la notificacion.
  - `body` — Cuerpo/descripcion.
  - `notification_type` — Enum: `alert_triggered`, `earnings_reminder`, `system`, `promotion`.
  - `read` — Boolean, default false.
  - `notifiable` — Referencia polimorfica al recurso asociado (AlertRule, EarningsEvent, etc.).
  - `created_at` — Timestamp para el calculo de tiempo relativo.

---

## Formularios y acciones

- **PATCH** `/notifications/:id/read` — Marcar una notificacion individual como leida.
- **PATCH** `/notifications/mark_all_read` — Marcar todas las notificaciones como leidas.

---

## Stimulus controllers

- `notification-controller` — Gestiona:
  - Toggle del dropdown (abrir/cerrar al clickear el icono de campana).
  - Cerrar al clickear fuera del panel.
  - Marcar como leida al clickear una notificacion individual.
  - Actualizar el badge count al marcar como leidas.

---

## Turbo

- **Turbo Stream via ActionCable** — Prepend de nuevas notificaciones en tiempo real al panel abierto.
- **Turbo Stream** para actualizar el badge count en el navbar sin recargar la pagina.
- Canal: `NotificationsChannel` suscrito al usuario actual.

---

## Empty state

Icono: `notifications_none`. Texto: "No notifications yet." Sin boton de accion.

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

- Segun el Product expert, este componente conecta el flujo: `AlertRuleTriggered` -> handler `CreateNotification` -> Turbo Stream broadcast al navbar del usuario.
- El handler `CreateNotification` escucha el evento `AlertRuleTriggered` en el EventBus y crea un registro `Notification`.
- El dropdown se posiciona debajo del icono de campana, alineado a la derecha, con ancho fijo (~380px) y sombra.
- Maximo 10 notificaciones en el panel. "View All Notifications" muestra el historial completo.
- Las notificaciones de tipo `promotion` son opcionales y se pueden desactivar en el perfil del usuario.
- Considerar agrupar notificaciones del mismo tipo si hay muchas en poco tiempo (ej. "5 alerts triggered").
