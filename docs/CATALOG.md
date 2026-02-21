# Stockerly — Catalogo de Paginas

> Fuente de verdad para el mapa completo de pantallas del producto.
> Cada entrada enlaza a su SPEC.md (metadatos detallados) y a su diseno de referencia.
>
> **Actualizar este archivo al:** agregar una pagina nueva, cambiar una ruta, cambiar el estado de implementacion.

---

## Leyenda de estados

| Icono | Estado | Descripcion |
|-------|--------|-------------|
| D | design | Solo existe el diseno de referencia |
| H | static-html | Vista implementada con datos hardcodeados |
| B | backend-wired | Conectada al backend real |
| T | tested | Con request specs pasando |
| OK | complete | Completa: HTML + backend + tests |

---

## Zona Publica

| # | Pagina | Ruta | Layout | Controlador | SPEC | Estado |
|---|--------|------|--------|-------------|------|--------|
| 1 | Landing Page | `/` | `public` | `pages#landing` | [SPEC](../designs/public/landing/SPEC.md) | H |
| 2 | Trend Explorer | `/trends` | `public` | `trends#index` | [SPEC](../designs/public/trends/SPEC.md) | H |
| 3 | Open Source | `/open-source` | `public` | `pages#open_source` | [SPEC](../designs/public/open-source/SPEC.md) | H |
| 4 | Login | `/login` | `public` | `sessions#new` | [SPEC](../designs/public/login/SPEC.md) | OK |
| 5 | Registro | `/register` | `public` | `registrations#new` | [SPEC](../designs/public/register/SPEC.md) | OK |
| 6 | Forgot Password | `/forgot-password` | `public` | `password_resets#new` | [SPEC](../designs/public/forgot-password/SPEC.md) | OK |
| 7 | Reset Password | `/reset-password/:token` | `public` | `password_resets#edit` | [SPEC](../designs/public/reset-password/SPEC.md) | OK |

## Zona Legal

| # | Pagina | Ruta | Layout | Controlador | SPEC | Estado |
|---|--------|------|--------|-------------|------|--------|
| 8 | Privacy Policy | `/privacy` | `legal` | `legal#privacy` | [SPEC](../designs/legal/privacy/SPEC.md) | H |
| 9 | Terms of Service | `/terms` | `legal` | `legal#terms` | [SPEC](../designs/legal/terms/SPEC.md) | H |
| 10 | Risk Disclosure | `/risk-disclosure` | `legal` | `legal#risk_disclosure` | [SPEC](../designs/legal/risk-disclosure/SPEC.md) | H |

## Zona App (Autenticada)

| # | Pagina | Ruta | Layout | Controlador | SPEC | Estado |
|---|--------|------|--------|-------------|------|--------|
| 11 | Dashboard | `/dashboard` | `app` | `dashboard#show` | [SPEC](../designs/app/dashboard/SPEC.md) | H |
| 12 | Market Explorer | `/market` | `app` | `market#index` | [SPEC](../designs/app/market/SPEC.md) | H |
| 13 | Portfolio | `/portfolio` | `app` | `portfolios#show` | [SPEC](../designs/app/portfolio/SPEC.md) | H |
| 14 | Alerts | `/alerts` | `app` | `alerts#index` | [SPEC](../designs/app/alerts/SPEC.md) | H |
| 15 | Earnings Calendar | `/earnings` | `app` | `earnings#index` | [SPEC](../designs/app/earnings/SPEC.md) | H |
| 16 | Profile | `/profile` | `app` | `profiles#show` | [SPEC](../designs/app/profile/SPEC.md) | H |

## Zona Admin

| # | Pagina | Ruta | Layout | Controlador | SPEC | Estado |
|---|--------|------|--------|-------------|------|--------|
| 17 | Admin: Assets | `/admin/assets` | `admin` | `admin/assets#index` | [SPEC](../designs/admin/assets/SPEC.md) | H |
| 18 | Admin: Logs | `/admin/logs` | `admin` | `admin/logs#index` | [SPEC](../designs/admin/logs/SPEC.md) | H |
| 19 | Admin: Users | `/admin/users` | `admin` | `admin/users#index` | [SPEC](../designs/admin/users/SPEC.md) | H |

## Componentes Compartidos

| # | Componente | Zona | Trigger / Ruta | SPEC | Estado |
|---|-----------|------|----------------|------|--------|
| 20 | Onboarding Wizard | app | Primer login post-registro | [SPEC](../designs/shared/onboarding/SPEC.md) | D |
| 21 | Empty States | transversal | Condicion: sin datos | [SPEC](../designs/shared/empty-states/SPEC.md) | H |
| 22 | Notification Panel | app | Click en campana (navbar) | [SPEC](../designs/shared/notification-panel/SPEC.md) | H |
| 23 | News Feed | app | `/news` (TBD) | [SPEC](../designs/shared/news-feed/SPEC.md) | D |
| 24 | Global Search | app | Click/Cmd+K en search bar | [SPEC](../designs/shared/global-search/SPEC.md) | H |
| 25 | Error Pages | shared | 404 / 500 errors | [SPEC](../designs/shared/error-pages/SPEC.md) | H |

---

## Conteo por estado

| Estado | Cantidad |
|--------|----------|
| complete (OK) | 4 |
| tested (T) | 0 |
| backend-wired (B) | 0 |
| static-html (H) | 19 |
| design (D) | 2 |
| **Total** | **25** |

---

## Backlog (pantallas futuras)

| Pantalla | Justificacion | Prioridad |
|----------|--------------|-----------|
| Asset Detail Page | Pagina dedicada por activo con chart completo | Media |
| Trade Detail Modal | Ver detalle de una transaccion | Baja |
| Notifications Page (/notifications) | Vista completa de todas las notificaciones | Baja |
