# Alerts — Spec

> **Zona:** app
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/alerts` |
| **Layout** | `app` |
| **Controlador** | `AlertsController#index, #create, #update, #destroy` |
| **Vista principal** | `app/views/alerts/index.html.erb` |
| **Fase** | Fase 3 |

---

## Diseno de referencia

- **Captura:** screen.png
- **HTML Stitch:** code.html
- **Variantes:** Ninguna

---

## Secciones y elementos

### 1. Stats Row

| Stat | Descripcion |
|------|-------------|
| **Triggered Today** | Cantidad de alertas disparadas hoy |
| **Active Rules** | Cantidad de reglas de alerta activas |

### 2. Create New Alert Form

- Formulario para crear una nueva regla de alerta
- Campos: ticker (autocomplete), condicion (dropdown: above/below/crosses), umbral (input numerico)
- Partial: `_create_form.html.erb`

### 3. Active Alert Rules Table

- Tabla con las reglas de alerta activas del usuario
- Columnas: Asset, Condition, Threshold, Status, Created, Actions
- Acciones por fila: Pause (toggle), Delete
- Partial: `_rules_table.html.erb`

### 4. Live Alert Feed (sidebar)

- Feed en tiempo real de alertas disparadas
- Badge "LIVE" animado
- Timeline vertical con eventos recientes
- Partial: `_live_feed.html.erb`

### 5. Delivery Preferences

- Toggles para configurar canales de entrega de notificaciones
- Opciones: Push, Email, SMS
- Partial: `_delivery_preferences.html.erb`

---

## Datos necesarios

Datos hardcodeados (Fase 3). Modelos futuros listados:

| Modelo | Uso |
|--------|-----|
| `AlertRule` | Reglas de alerta del usuario (ticker, condicion, umbral, estado) |
| `AlertEvent` | Eventos de alerta disparados |
| `AlertPreference` | Preferencias de entrega (push, email, sms) |
| `Asset` | Datos del activo para autocomplete y referencia |

---

## Formularios y acciones

### Create Alert

| Campo | Tipo | Metodo |
|-------|------|--------|
| Ticker | text input (autocomplete) | POST `/alerts` |
| Condition | select (above/below/crosses) | POST `/alerts` |
| Threshold | number input | POST `/alerts` |

### Update Alert (Pause/Resume)

| Accion | Metodo |
|--------|--------|
| Toggle pause | PATCH `/alerts/:id` |

### Delete Alert

| Accion | Metodo |
|--------|--------|
| Eliminar regla | DELETE `/alerts/:id` |

Nota: En Fase 3 todas las acciones redirigen a `/alerts` con un mensaje flash "(demo mode)".

---

## Stimulus controllers

| Controller | Archivo | Uso |
|------------|---------|-----|
| `toggle` | `toggle_controller.js` | Toggles de delivery preferences (Push, Email, SMS) |

Pendiente en fases futuras: controlador de formulario con autocomplete para ticker y validacion en cliente.

---

## Turbo

No hay Turbo Frames implementados actualmente. En fases futuras:

- Turbo Frame para la tabla de reglas (CRUD sin recarga completa)
- Turbo Stream para el live feed (prepend de nuevos eventos via ActionCable)

---

## Empty states

| Seccion | Mensaje |
|---------|---------|
| Rules vacio | "Create your first price alert" |
| Feed vacio | "Alerts will appear here in real-time" |

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

- `AlertEvaluator` domain service evaluara condiciones cuando se reciba el evento `AssetPriceUpdated`.
- Partials: `_create_form`, `_rules_table`, `_live_feed`, `_delivery_preferences`.
- El controlador hereda de `AuthenticatedController` (requiere login).
- Las acciones `create`, `update`, `destroy` ya estan implementadas en el controlador pero redirigen con mensajes demo.
- El live feed usara ActionCable + Turbo Streams en fases futuras para actualizaciones en tiempo real.
