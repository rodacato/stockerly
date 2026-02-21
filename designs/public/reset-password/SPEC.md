# Reset Password — Spec

> **Zona:** Publica (auth)
> **Estado:** complete

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/reset-password/:token` (GET), `/reset-password/:token` (PATCH) |
| **Layout** | `public` (variante auth) |
| **Controlador** | `PasswordResetsController#edit` / `PasswordResetsController#update` |
| **Vista principal** | `app/views/password_resets/edit.html.erb` |
| **Fase** | 2 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`
- **Variantes:** Ninguna

---

## Secciones y elementos

- **Split card:** Tarjeta dividida en dos columnas — branding/ilustracion a la izquierda, formulario a la derecha.
- **New Password field:** Campo para la nueva contrasena.
- **Confirm Password field:** Campo de confirmacion de la nueva contrasena.
- **"Reset Password" button:** Boton para confirmar el cambio de contrasena.
- **"Back to Login" link:** Link de regreso a `/login`.

---

## Datos necesarios

- **Modelo:** User
- **Campos usados:** password, password_confirmation
- **Mecanismo:** Token validado via `generates_token_for :password_reset` (signed virtual token, no almacenado en DB)

---

## Formularios y acciones

| Accion | Metodo | Ruta | Params |
|--------|--------|------|--------|
| Reset password | PATCH | `/reset-password/:token` | `password`, `password_confirmation` |

---

## Stimulus controllers

Ninguno identificado

---

## Turbo

No aplica

---

## Empty state

No aplica

---

## Estado de implementacion

| Etapa | Estado |
|-------|--------|
| Diseno (Stitch) | Completo |
| HTML estatico | Completo |
| Backend conectado | Completo |
| Tests | Completo (69 specs totales, Fase 2) |

---

## Notas

- Fase 2 completa en backend y tests, pero el diseno Stitch esta pendiente.
- El token en la URL es un signed virtual token generado por `generates_token_for :password_reset` de Rails 8.1 — no se almacena en la base de datos.
- Si el token es invalido o ha expirado, se redirige al usuario con un mensaje de error.
- Tras un reset exitoso, se redirige a `/login` con un mensaje de confirmacion.
