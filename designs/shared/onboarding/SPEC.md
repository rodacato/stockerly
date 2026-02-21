# Onboarding Wizard — Spec

> **Zona:** shared
> **Estado:** design

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/onboarding` (TBD) |
| **Layout** | `app` |
| **Controlador** | `OnboardingController` (nuevo) |
| **Vista principal** | `app/views/onboarding/show.html.erb` |
| **Fase** | Fase 3 |

---

## Diseno de referencia

- **Capturas:** `screen-step1.png`, `screen-step2.png`, `screen-step3.png`
- **HTML Stitch:** `code-step1.html`, `code-step2.html`, `code-step3.html`

---

## Secciones y elementos

- **Progress bar:** Barra de progreso en la parte superior mostrando el paso actual (1/3, 2/3, 3/3). Segmentos con color primario `#004a99` para pasos completados, gris para pendientes.

- **Step 1: "Choose Your Markets"**
  - Tarjetas seleccionables con icono y titulo para cada mercado:
    - US Stocks (icono: `trending_up`)
    - Crypto (icono: `currency_bitcoin`)
    - International (icono: `public`)
    - ETFs (icono: `account_balance`)
    - Indices (icono: `bar_chart`)
  - Seleccion multiple permitida. Visual: borde azul + checkmark al seleccionar.
  - Boton "Continue" (habilitado cuando al menos 1 mercado seleccionado).

- **Step 2: "Pick Your First Stocks"**
  - **Search bar** — Busqueda de activos por nombre o ticker.
  - **Popular stocks list** — Grid/lista de activos populares con logo, nombre, ticker y boton "+" para agregar.
  - **Selected counter** — Indicador de cuantos activos se han seleccionado (ej. "3 of 3 minimum").
  - Minimo 3 activos requeridos para continuar.
  - Boton "Continue" (habilitado cuando >= 3 seleccionados).

- **Step 3: "You're All Set!"**
  - **Dashboard preview** — Vista previa reducida del dashboard con los activos seleccionados.
  - **Tooltip tour** — Indicadores visuales tipo tooltip apuntando a secciones clave del dashboard.
  - **Summary** — Resumen de mercados y activos elegidos.
  - Boton "Go to Dashboard" (primario, dirige a `/dashboard`).

- **"Skip" link:** Presente en cada paso. Permite saltar el onboarding y ir directamente al dashboard.

---

## Datos necesarios

- `Asset` — Lista de activos populares para el Step 2 (filtrados por mercado seleccionado en Step 1).
- `WatchlistItem` — Creados en Step 2 al agregar activos al watchlist del usuario.

Criterio de activacion: el usuario tiene >= 3 `WatchlistItem` asociados.

---

## Formularios y acciones

- **POST** `/onboarding/step1` — Guardar preferencias de mercado del usuario.
- **POST** `/onboarding/step2` — Crear WatchlistItems para los activos seleccionados.
- **PATCH** `/onboarding/complete` — Marcar onboarding como completado en el perfil del usuario.

---

## Stimulus controllers

- `onboarding-controller` — Gestiona la navegacion entre pasos, validacion de seleccion minima, y animaciones de transicion.
- `selectable-card-controller` — Toggle de seleccion en tarjetas de mercado (Step 1) y activos (Step 2).
- `search-controller` — Busqueda de activos en Step 2 con debounce.

---

## Turbo

- Turbo Frame para el contenido de cada paso, permitiendo transiciones sin recarga completa.
- Turbo Stream para actualizar el contador de activos seleccionados en Step 2 al agregar/quitar.

---

## Empty state

No aplica directamente. Si la busqueda en Step 2 no encuentra resultados: "No assets found for 'xyz'. Try a different search term."

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

- Critico para activacion de usuarios segun el Product Strategist. El onboarding es el primer paso despues del registro.
- Se dispara en el primer login posterior al registro. Si el usuario ya tiene >= 3 watchlist items, no se muestra.
- El "Skip" link lleva al dashboard pero no marca el onboarding como completado, permitiendo que se muestre un banner recordatorio.
- Las preferencias de mercado del Step 1 se pueden usar para personalizar el feed del dashboard.
- Considerar almacenar `onboarding_completed_at` en el modelo `User` para tracking.
