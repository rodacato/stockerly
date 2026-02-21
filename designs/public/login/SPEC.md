# Login — Spec

> **Zona:** Publica (auth)
> **Estado:** complete

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/login` (GET), `/login` (POST) |
| **Layout** | `public` (variante auth) |
| **Controlador** | `SessionsController#new` / `SessionsController#create` |
| **Vista principal** | `app/views/sessions/new.html.erb` |
| **Fase** | 2 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`
- **Variantes:** El diseno es compartido con Register — misma pantalla con pestanas (Login tab activa aqui)

---

## Secciones y elementos

- **Split card:** Tarjeta dividida en dos columnas — branding/ilustracion a la izquierda, formulario a la derecha.
- **Login tab activa:** Pestana de Login resaltada, pestana de Register como link inactivo.
- **Email field:** Campo de email con validacion.
- **Password field:** Campo de password.
- **Remember me checkbox:** Checkbox para mantener la sesion activa.
- **Forgot password link:** Link a `/forgot-password`.
- **Submit button:** Boton "Sign In" o "Log In".
- **Register tab link:** Link a `/register` para cambiar de pestana.

---

## Datos necesarios

- **Modelo:** User
- **Campos usados:** email, password_digest
- **Asociaciones:** RememberToken (para "remember me")

---

## Formularios y acciones

| Accion | Metodo | Ruta | Params |
|--------|--------|------|--------|
| Login | POST | `/login` | `email`, `password`, `remember_me` |

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

- Fase 2 completa. Flujo totalmente funcional con backend conectado y tests.
- Remember me usa rotacion segura de tokens (RememberToken model).
- Rate limited: 5 intentos por minuto para prevenir fuerza bruta.
- El `screen.png` y `code.html` muestran ambas pestanas (Login y Register) ya que comparten el mismo export de Stitch.
- `has_secure_password` de Rails 8.1 maneja la autenticacion.
