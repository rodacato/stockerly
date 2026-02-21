# Forgot Password — Spec

> **Zona:** Publica (auth)
> **Estado:** complete

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/forgot-password` (GET), `/forgot-password` (POST) |
| **Layout** | `public` (variante auth) |
| **Controlador** | `PasswordResetsController#new` / `PasswordResetsController#create` |
| **Vista principal** | `app/views/password_resets/new.html.erb` |
| **Fase** | 2 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`
- **Variantes:** Ninguna

---

## Secciones y elementos

- **Split card:** Tarjeta dividida en dos columnas — branding/ilustracion a la izquierda, formulario a la derecha.
- **Email field:** Campo de email para solicitar el reset.
- **"Send Reset Link" button:** Boton de envio del enlace de recuperacion.
- **"Back to Login" link:** Link de regreso a `/login`.
- **Success message area:** Zona para mostrar mensaje de confirmacion tras envio exitoso.

---

## Datos necesarios

- **Modelo:** User
- **Campos usados:** email
- **Mecanismo:** `generates_token_for :password_reset` (built-in de Rails 8.1 `has_secure_password`)

---

## Formularios y acciones

| Accion | Metodo | Ruta | Params |
|--------|--------|------|--------|
| Request reset | POST | `/forgot-password` | `email` |

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
- No se necesitan columnas adicionales en la base de datos para el token de reset. Rails 8.1 `has_secure_password` provee `generates_token_for :password_reset` que genera tokens virtuales firmados.
- El token es un signed token que no se almacena en DB — se valida criptograficamente.
- Por seguridad, la respuesta siempre indica exito independientemente de si el email existe o no.
