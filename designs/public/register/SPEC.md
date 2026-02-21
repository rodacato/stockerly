# Register — Spec

> **Zona:** Publica (auth)
> **Estado:** complete

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/register` (GET), `/register` (POST) |
| **Layout** | `public` (variante auth) |
| **Controlador** | `RegistrationsController#new` / `RegistrationsController#create` |
| **Vista principal** | `app/views/registrations/new.html.erb` |
| **Fase** | 2 |

---

## Diseno de referencia

- **Captura:** Ver `../login/screen.png` (diseno compartido con Login)
- **HTML Stitch:** Ver `../login/code.html` (diseno compartido con Login)
- **Variantes:** Misma pantalla que Login pero con la pestana Register activa

---

## Secciones y elementos

- **Split card:** Tarjeta dividida en dos columnas — branding/ilustracion a la izquierda, formulario a la derecha.
- **Register tab activa:** Pestana de Register resaltada, pestana de Login como link inactivo.
- **Full name field:** Campo de nombre completo.
- **Email field:** Campo de email con validacion.
- **Password field:** Campo de password.
- **Password confirmation field:** Campo de confirmacion de password.
- **Terms checkbox:** Checkbox de aceptacion de terminos y condiciones (requerido).
- **Submit button:** Boton "Create Account" o "Sign Up".
- **Login tab link:** Link a `/login` para cambiar de pestana.

---

## Datos necesarios

- **Modelo:** User
- **Campos usados:** full_name, email, password_digest
- **Validaciones:** Presencia de nombre, email unico, password minimo, terminos aceptados

---

## Formularios y acciones

| Accion | Metodo | Ruta | Params |
|--------|--------|------|--------|
| Register | POST | `/register` | `full_name`, `email`, `password`, `password_confirmation`, `terms_accepted` |

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
| Diseno (Stitch) | Completo (compartido con Login) |
| HTML estatico | Completo |
| Backend conectado | Completo |
| Tests | Completo (69 specs totales, Fase 2) |

---

## Notas

- Fase 2 completa. Flujo totalmente funcional con backend conectado y tests.
- La referencia de diseno esta en `../login/` ya que Login y Register comparten un unico export de Stitch.
- No hay autenticacion social en v1 — solo email/password.
- El checkbox de terminos es obligatorio para completar el registro.
