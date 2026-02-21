# Stockerly - Mapa de Implementacion Frontend (Rails)

> Este documento sirve como plan maestro para implementar las vistas de Stockerly en Ruby on Rails.
> Todas las paginas se implementaran primero como HTML estatico con datos hardcodeados,
> y progresivamente se conectaran al backend.

---

## Indice

1. [Resumen de Paginas](#1-resumen-de-paginas)
2. [Jerarquia de Acceso](#2-jerarquia-de-acceso)
3. [Layouts de Rails](#3-layouts-de-rails)
4. [Elementos Compartidos (Partials)](#4-elementos-compartidos-partials)
5. [Controladores y Vistas](#5-controladores-y-vistas)
6. [Mapa de Rutas](#6-mapa-de-rutas)
7. [Propuesta de Modelado](#7-propuesta-de-modelado)
8. [Fases de Implementacion](#8-fases-de-implementacion)
9. [Referencia Visual por Pagina](#9-referencia-visual-por-pagina)

---

## 1. Resumen de Paginas

| # | Carpeta | Pagina | Zona | Layout |
|---|---------|--------|------|--------|
| 1 | `landing_page_-_trendstocker` | Landing Page | Publica | Public |
| 2 | `acceso_y_registro_-_trendstocker` | Login / Registro | Publica | Public |
| 3 | `trendstocker_dashboard` | Trend Explorer (vista publica) | Publica | Public |
| 4 | `open_source_project` | Open Source Project | Publica | Public |
| 5 | `privacy_policy` | Privacy Policy | Publica | Legal |
| 6 | `terms_of_service` | Terms of Service | Publica | Legal |
| 7 | `risk_disclosure` | Risk Disclosure | Publica | Legal |
| 8 | `dashboard_principal_-_trendstocker` | Dashboard Principal | Autenticada | App |
| 9 | `explorador_de_mercado_-_trendstocker` | Explorador de Mercado | Autenticada | App |
| 10 | `gestión_de_portafolio_-_trendstocker` | Gestion de Portafolio | Autenticada | App |
| 11 | `alertas_de_tendencia_-_trendstocker` | Alertas de Tendencia | Autenticada | App |
| 12 | `calendario_de_earnings_-_trendstocker` | Calendario de Earnings | Autenticada | App |
| 13 | `mi_perfil_-_trendstocker` | Mi Perfil | Autenticada | App |
| 14 | `admin:_gestión_de_activos` | Admin: Gestion de Activos | Admin | Admin |
| 15 | `admin:_logs_de_sistema` | Admin: Logs de Sistema | Admin | Admin |
| 16 | `admin:_usuarios_e_integraciones` | Admin: Usuarios e Integraciones | Admin | Admin |
| 17 | `shared/onboarding` | Onboarding Wizard (3 pasos) | Autenticada | App |
| 18 | `shared/empty-states` | Empty States Collection | Transversal | Varios |
| 19 | `shared/notification-panel` | Notification Panel | Autenticada | App |
| 20 | `shared/news-feed` | News Feed | Autenticada | App |
| 21 | `shared/global-search` | Global Search | Autenticada | App |
| 22 | `shared/error-pages` | Error Pages (404/500) | Publica | - |
| 23 | `public/forgot-password` | Forgot Password | Publica | Public |
| 24 | `public/reset-password` | Reset Password | Publica | Public |

---

## 2. Jerarquia de Acceso

```
Stockerly
|
|-- PUBLICO (sin autenticacion)
|   |-- Landing Page                    /
|   |-- Login / Registro                /login, /register
|   |-- Trend Explorer (publico)        /trends
|   |-- Open Source                     /open-source
|   |-- Privacy Policy                  /privacy
|   |-- Terms of Service               /terms
|   |-- Risk Disclosure                 /risk-disclosure
|
|-- USUARIO AUTENTICADO (requiere login)
|   |-- Dashboard Principal             /dashboard
|   |-- Explorador de Mercado           /market
|   |-- Gestion de Portafolio           /portfolio
|   |-- Alertas de Tendencia            /alerts
|   |-- Calendario de Earnings          /earnings
|   |-- Mi Perfil                       /profile
|   |-- News Feed                       /news
|   |-- Onboarding Wizard               (primer login post-registro)
|   |-- Notification Panel              (dropdown en navbar)
|   |-- Global Search                   (Cmd+K / search bar)
|
|-- ADMINISTRADOR (requiere rol admin)
|   |-- Gestion de Activos              /admin/assets
|   |-- Logs de Sistema                 /admin/logs
|   |-- Usuarios e Integraciones        /admin/users
|
|-- ERROR PAGES (publico)
    |-- 404 Not Found                   /404
    |-- 500 Internal Server Error       /500
```

---

## 3. Layouts de Rails

Se necesitan **5 archivos de layout** en `app/views/layouts/` (1 base + 4 especificos):

### 3.1 `application.html.erb` (Layout base)
- Meta tags, Tailwind CSS CDN, Material Symbols, font Inter
- `<%= yield %>` para el contenido
- Todos los demas layouts heredan de este o lo reemplazan

### 3.2 `public.html.erb` - Paginas publicas
**Usa:** Landing, Trend Explorer, Open Source, Login/Registro (con variante CSS para card centrada)
- **Header:** Logo Stockerly + nav horizontal (Analysis, Portfolio, Alerts) + botones Login / Get Started
- **Footer:** Multi-columna (Platform, Company, Legal) + iconos sociales + disclaimer
- Contenido centrado `max-w-7xl`
- **Variante auth:** Las paginas de autenticacion (Login/Registro) usan este mismo layout con una clase CSS que centra el contenido en una card vertical y horizontalmente, y muestra un footer compacto

### 3.3 `app.html.erb` - Aplicacion autenticada
**Usa:** Dashboard, Market Explorer, Portfolio, Alerts, Earnings, Profile
- **Header sticky:** Logo + barra busqueda + nav con item activo: `[Logo] [Dashboard] [Markets] [Portfolio] [Alerts] [Earnings] [busqueda] [notificaciones] [Avatar]` -- 5 items fijos + busqueda + notificaciones + avatar con dropdown
- **Footer:** Multi-columna similar al publico
- Contenido centrado `max-w-7xl`

### 3.4 `admin.html.erb` - Panel de administracion
**Usa:** Assets, Logs, Users/Integrations
- **Sin header superior**
- **Sidebar fijo izquierdo (w-64):** Logo "Stockerly Admin" + menu vertical (Assets, Logs, Users, Integrations) + perfil admin en el pie
- **Area principal:** scrollable con header interno (breadcrumbs) + contenido
- **Footer:** Barra de estado del sistema (version, API status, DB status)

### 3.5 `legal.html.erb` - Paginas legales
**Usa:** Privacy Policy, Terms of Service, Risk Disclosure
- **Header:** Mismo que `public` con nav (Home, Products, About, Contact)
- **Breadcrumbs:** Home / Nombre de pagina
- **Layout 2 columnas:** Sidebar sticky con Table of Contents (1/4) + contenido articulo (3/4)
- **Footer:** Multi-columna + boton "Back to Top" flotante

---

## 4. Elementos Compartidos (Partials)

### 4.1 Partials de Layout (`app/views/shared/`)

| Partial | Usado en | Descripcion |
|---------|----------|-------------|
| `_public_navbar.html.erb` | public, legal | Logo + nav publica + Login/Get Started |
| `_app_navbar.html.erb` | app | Logo + search + nav autenticada + notificaciones + avatar |
| `_admin_sidebar.html.erb` | admin | Sidebar con menu vertical + perfil admin |
| `_public_footer.html.erb` | public, legal, app | Footer multi-columna con links y sociales |
| `_admin_footer.html.erb` | admin | Barra de estado del sistema |
| `_breadcrumbs.html.erb` | legal, admin | Navegacion breadcrumb |
| `_legal_toc_sidebar.html.erb` | legal | Table of contents sticky lateral |
| `_flash.html.erb` | todos los layouts | Toast/flash messages con auto-dismiss (Stimulus) |
| `_confirm_dialog.html.erb` | todos los layouts | Modal de confirmacion para acciones destructivas |

### 4.2 Partials de Componentes (`app/views/components/`)

| Partial | Usado en | Descripcion |
|---------|----------|-------------|
| `_stat_card.html.erb` | Dashboard, Portfolio, Alerts, Admin | Tarjeta KPI (titulo, valor, cambio %) |
| `_asset_row.html.erb` | Watchlist, Market Explorer, Portfolio | Fila de activo con precio, cambio, sparkline |
| `_news_card.html.erb` | Dashboard | Card de noticia con imagen, ticker, fuente |
| `_trending_ticker.html.erb` | Dashboard | Ticker trending con cambio % |
| `_alert_rule_row.html.erb` | Alerts | Fila de regla de alerta con status |
| `_alert_event.html.erb` | Alerts | Evento de alerta en live feed |
| `_earnings_cell.html.erb` | Earnings Calendar | Celda del calendario con evento |
| `_earnings_sidebar_item.html.erb` | Earnings Calendar | Item de watchlist priority |
| `_index_card.html.erb` | Market Explorer | Tarjeta de indice (S&P, NASDAQ, etc.) |
| `_donut_chart.html.erb` | Portfolio | Grafico de torta CSS (portfolio allocation) |
| `_position_row.html.erb` | Portfolio | Fila de posicion con gain/loss |
| `_user_row.html.erb` | Admin Users | Fila de usuario con tier y status |
| `_integration_card.html.erb` | Admin Integrations | Card de proveedor de datos |
| `_log_row.html.erb` | Admin Logs | Fila de log con severity badge |
| `_feature_card.html.erb` | Landing, Open Source | Card de feature (icono, titulo, descripcion) |
| `_status_badge.html.erb` | Varios | Badge de estado (Active, Paused, Error, etc.) |
| `_sparkline.html.erb` | Dashboard, Portfolio, Profile | Mini grafico de tendencia CSS |
| `_market_status.html.erb` | Dashboard | Indicador de mercado (Open/Closed) |
| `_trend_score.html.erb` | Trend Explorer | Score circular 0-100 |
| `_back_to_top.html.erb` | Legal | Boton flotante "Back to Top" |
| `_notification_item.html.erb` | Notification Panel | Item individual de notificacion |
| `_notification_badge.html.erb` | App navbar | Badge de conteo de notificaciones no leidas |
| `_search_result_group.html.erb` | Global Search | Grupo de resultados por tipo |
| `_search_result_item.html.erb` | Global Search | Item individual de resultado |
| `_news_feed_item.html.erb` | News Feed | Item de noticia en el feed |
| `_onboarding_step.html.erb` | Onboarding | Paso individual del wizard |
| `_empty_state.html.erb` | Transversal | Componente de empty state reutilizable |

---

## 5. Controladores y Vistas

### 5.1 Zona Publica

#### `PagesController` - Paginas estaticas
```
app/controllers/pages_controller.rb
app/views/pages/
  landing.html.erb          # Landing page con hero, features, stats, CTA
  open_source.html.erb      # Pagina open source project
```

#### `TrendsController` - Trend Explorer publico
```
app/controllers/trends_controller.rb
app/views/trends/
  index.html.erb            # Dashboard de tendencias (filtros + stock detail + chart)
```

#### `LegalController` - Paginas legales
```
app/controllers/legal_controller.rb
app/views/legal/
  privacy.html.erb          # Privacy Policy (7 secciones)
  terms.html.erb            # Terms of Service (7 secciones)
  risk_disclosure.html.erb  # Risk Disclosure (5 secciones)
```

#### `SessionsController` - Autenticacion
```
app/controllers/sessions_controller.rb
app/views/sessions/
  new.html.erb              # Login (card split con form: email/password)
```

#### `RegistrationsController` - Registro
```
app/controllers/registrations_controller.rb
  (comparte vista con sessions o usa su propia)
```

#### `PasswordResetsController` - Recuperacion de password
```
app/controllers/password_resets_controller.rb
app/views/password_resets/
  new.html.erb              # Formulario "Forgot password?" (campo email + submit)
  edit.html.erb             # Formulario "Reset password" (new password + confirm + submit)
```
**Flujo:** (1) Usuario ingresa email -> se genera token y se envia email con link. (2) Usuario abre link con token -> formulario para nueva password. (3) Al guardar, se invalida el token y se redirige a login.
**Campos en User:** `password_reset_token` (string, unique index), `password_reset_sent_at` (datetime). Ver DATABASE_SCHEMA.md.

### 5.2 Zona Autenticada (Usuario)

#### `DashboardController`
```
app/controllers/dashboard_controller.rb
app/views/dashboard/
  show.html.erb             # Dashboard principal (KPIs + watchlist + news + trending)
```
**Contenido:** Total Balance, Day Gain/Loss, Buying Power, Market Sentiment, Watchlist Performance table, Relevant News feed, Trending Today sidebar, Weekly Insight, Market Status. Soporte multidivisa con selector de divisa (USD/EUR/MXN) en header — misma vista con parametro `currency`.

#### `MarketController`
```
app/controllers/market_controller.rb
app/views/market/
  index.html.erb            # Explorador de mercado (indices + filtros + tabla paginada)
```
**Contenido:** 4 Index cards (S&P, NASDAQ, DOW, FTSE), filtros avanzados (Sector, Market Cap, Volatility, Trend Strength), tabla Market Listings con paginacion, botones Export CSV / Real-time Updates

#### `PortfolioController`
```
app/controllers/portfolio_controller.rb
app/views/portfolio/
  show.html.erb             # Portafolio (KPIs + allocation chart + posiciones)
```
**Contenido:** 3 KPI cards (Total Value, Unrealized Gain, Buying Power), Donut chart allocation por sector, Tabs (Open Positions, Closed Positions, Dividend History), tabla de posiciones. Soporte multidivisa con columna currency, domestic/international split, FX rates y parametro `currency` para conversion.

#### `AlertsController`
```
app/controllers/alerts_controller.rb
app/views/alerts/
  index.html.erb            # Alertas (form + reglas + live feed + preferences)
```
**Contenido:** Stats (Triggered Today, Active Rules), formulario "Create New Alert" (ticker, condition, threshold), tabla Active Alert Rules con actions, Live Alert Feed sidebar con timeline, Delivery Preferences (Push, Email, SMS)

#### `EarningsController`
```
app/controllers/earnings_controller.rb
app/views/earnings/
  index.html.erb            # Calendario de earnings (sidebar + calendar grid)
```
**Contenido:** Toggles My Watchlist/All Markets, navegador de mes, Watchlist Priority sidebar (5 eventos), calendario grid 7 columnas con eventos BMO/AMC, Earnings Pro Tips card, leyenda

#### `ProfileController`
```
app/controllers/profile_controller.rb
app/views/profile/
  show.html.erb             # Mi perfil (info + settings + watchlist)
```
**Contenido:** Header con avatar, nombre, badges (Verified), Personal Information form, Account Settings (toggles notificaciones, privacy), Watchlist table

#### `NewsController` - News Feed
```
app/controllers/news_controller.rb
app/views/news/
  index.html.erb            # Feed de noticias con filtros y paginacion infinita
```
**Contenido:** Feed de articulos financieros, filtros (All/Stocks/Crypto/Economy, Watchlist), infinite scroll, sidebar trending topics

#### `OnboardingController` - Onboarding Wizard
```
app/controllers/onboarding_controller.rb
app/views/onboarding/
  step1.html.erb            # Elegir mercados/sectores de interes
  step2.html.erb            # Seleccionar stocks para watchlist inicial
  step3.html.erb            # Confirmacion y tour del dashboard
```
**Contenido:** Wizard de 3 pasos post-registro. Paso 1: mercados. Paso 2: stocks populares. Paso 3: exito + CTA al dashboard.

### 5.3 Zona Admin

#### `Admin::AssetsController`
```
app/controllers/admin/assets_controller.rb
app/views/admin/assets/
  index.html.erb            # Gestion de activos (KPIs + tabla con tabs + paginacion)
```
**Contenido:** 3 KPI cards (Total Assets, Syncing, Alerts), Tabs (All/Stocks/Crypto), tabla con Name, Symbol, Source, Status, Actions (edit/toggle), paginacion

#### `Admin::LogsController`
```
app/controllers/admin/logs_controller.rb
app/views/admin/logs/
  index.html.erb            # Logs de sistema (filtros + tabla + stats)
```
**Contenido:** Filtros (search, Severity, Module, Time Range), tabla (Status, Task, Module, Timestamp, Duration, Action), 4 stats cards (Success Rate, Active Alerts, Avg Run Time, Storage), toggle Auto-refresh, Export CSV

#### `Admin::UsersController`
```
app/controllers/admin/users_controller.rb
app/views/admin/users/
  index.html.erb            # Usuarios (tabla) + Integraciones (cards)
```
**Contenido:** User Management table (Profile, Join Date, Status, Actions), paginacion. Market Data Connectivity: cards de proveedores (Polygon.io, CoinGecko) con API key, status, last sync + card "Add New Provider". Las integraciones se gestionan directamente en esta vista, sin controller separado.

---

## 6. Mapa de Rutas

```ruby
# config/routes.rb

Rails.application.routes.draw do
  # --- Paginas Publicas ---
  root "pages#landing"

  get "open-source",      to: "pages#open_source"
  get "trends",           to: "trends#index"

  # --- Legal ---
  get "privacy",          to: "legal#privacy"
  get "terms",            to: "legal#terms"
  get "risk-disclosure",  to: "legal#risk_disclosure"

  # --- Autenticacion ---
  get    "login",         to: "sessions#new"
  post   "login",         to: "sessions#create"
  delete "logout",        to: "sessions#destroy"
  get    "register",      to: "registrations#new"
  post   "register",      to: "registrations#create"

  # --- Password Reset ---
  get    "forgot-password",             to: "password_resets#new"
  post   "forgot-password",             to: "password_resets#create"
  get    "reset-password/:token",       to: "password_resets#edit",   as: :reset_password
  patch  "reset-password/:token",       to: "password_resets#update"

  # --- Zona Autenticada ---
  get "dashboard",        to: "dashboard#show"
  get "market",           to: "market#index"
  get "news",             to: "news#index"

  resource  :portfolio,   only: [:show]
  resources :alerts,      only: [:index, :create, :update, :destroy]
  resources :earnings,    only: [:index]
  resource  :profile,     only: [:show, :update]

  # --- Onboarding ---
  get  "onboarding/step1", to: "onboarding#step1"
  get  "onboarding/step2", to: "onboarding#step2"
  get  "onboarding/step3", to: "onboarding#step3"
  post "onboarding/complete", to: "onboarding#complete"

  # --- Notifications ---
  resources :notifications, only: [:index, :update]

  # --- Global Search ---
  get "search", to: "search#index"

  # --- Zona Admin ---
  namespace :admin do
    resources :assets,       only: [:index, :create, :update, :destroy]
    resources :logs,         only: [:index]
    resources :users,        only: [:index, :update, :destroy]
    # Integraciones se gestionan dentro de Admin::UsersController#index (misma pagina).
    # No requiere resources :integrations ni controller separado — la seccion de
    # "Market Data Connectivity" con cards de proveedores vive en la vista de users.
    # Ver sec. 5.3 para detalles.
  end
end
```

---

## 7. Propuesta de Modelado

### 7.1 Diagrama de Entidades

```
User ──────────────── Portfolio
 |  1            1       |
 |                       | 1
 | *                     |
 WatchlistItem (join)  Position *
 |                       |
 | *                     |
 Asset ─────────────────-+
 |  1
 |
 +── TrendScore
 +── EarningsEvent
 +── MarketIndex (para indices)

User ── AlertRule * ── AlertEvent *
User ── AlertPreference (1:1)

Admin:
  SystemLog
  Integration
```

> Ver [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) sec. 1 para el ERD completo con todos los modelos.

### 7.2 Modelos Detallados

Para la definicion completa de todos los modelos, migraciones y seeds, ver [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md).

---

## 8. Fases de Implementacion

### Fase 0: Setup Base
- [ ] Configurar Tailwind CSS (build con Rails, no CDN)
- [ ] Agregar Material Symbols (Google Fonts)
- [ ] Agregar font Inter
- [ ] Crear los 5 layouts (public, app, admin, legal, application base)
- [ ] Crear todos los partials de layout (navbars, footers, sidebars, flash, confirm dialog)
- [ ] Configurar iconos y tipografia base

### Fase 1: Paginas Publicas (sin autenticacion)
- [ ] `PagesController#landing` - Landing page completa
- [ ] `LegalController` - Privacy, Terms, Risk Disclosure
- [ ] `TrendsController#index` - Trend Explorer publico
- [ ] Defer Open Source page para fase posterior

### Fase 2: Autenticacion
- [ ] `SessionsController#new` - Vista Login
- [ ] `RegistrationsController#new` - Formulario de registro
- [ ] `PasswordResetsController` - Forgot password + Reset password
- [ ] Implementar autenticacion basica (bcrypt)
- [ ] Rate limiting en login y password reset
- [ ] Middleware de autenticacion para zona app
- [ ] Redireccion login -> dashboard

### Fase 3: Vistas Estaticas + Empty States
- [ ] `DashboardController#show` - Dashboard con datos hardcodeados
- [ ] `MarketController#index` - Explorador de mercado con tabla estatica
- [ ] `PortfolioController#show` - Portafolio con posiciones hardcodeadas
- [ ] `AlertsController#index` - Alertas con form y feed estatico
- [ ] `EarningsController#index` - Calendario con eventos estaticos
- [ ] `ProfileController#show` - Perfil con form estatico
- [ ] Onboarding wizard (primer uso)
- [ ] Nav unificada con 5 items fijos funcionales
- [ ] Empty states para todas las vistas cuando no hay datos

### Fase 4: Admin
- [ ] Layout admin con sidebar funcional
- [ ] `Admin::AssetsController#index` - Tabla de activos
- [ ] `Admin::LogsController#index` - Tabla de logs
- [ ] `Admin::UsersController#index` - Tabla usuarios + integraciones cards
- [ ] AuditLog para acciones admin
- [ ] Sidebar badges (contadores en menu items)
- [ ] Middleware de autorizacion (solo admin)

### Fase 4.6: Componentes Compartidos
- [ ] Empty states para todas las vistas autenticadas
- [ ] Error pages (404, 500) con branding Stockerly
- [ ] Onboarding wizard (3 pasos post-registro)
- [ ] Notification panel (dropdown en navbar)
- [ ] Global search (Cmd+K, dropdown overlay)
- [ ] News feed page (`/news`)

### Fase 5: Modelos y Seeds
- [ ] Generar migraciones para todos los modelos: User, Asset, Portfolio, Position, WatchlistItem, AlertRule, AlertEvent, AlertPreference, EarningsEvent, NewsArticle, MarketIndex, TrendScore, SystemLog, Integration
- [ ] Modelos adicionales: Trade, PortfolioSnapshot, FxRate, AssetPriceHistory, Notification, AuditLog, Dividend, DividendPayment, RememberToken
- [ ] Crear seeds con datos de ejemplo (50+ assets con datos realistas)
- [ ] Asociaciones y validaciones
- [ ] Reemplazar datos hardcodeados por datos de BD

### Fase 6: Backend
- [ ] CRUD Watchlist (agregar/remover assets)
- [ ] CRUD Alert Rules (crear/editar/pausar/eliminar)
- [ ] Perfil de usuario (editar info, cambiar password)
- [ ] Admin: CRUD assets, gestionar usuarios
- [ ] AssetPriceUpdated event (pub/sub para actualizaciones de precio)
- [ ] AlertEvaluator (evaluar reglas al cambiar precios)
- [ ] Notifications (push, email digest)
- [ ] Portfolio snapshots (historico diario de valor)
- [ ] Busqueda global (assets, usuarios, alertas)
- [ ] Filtros y paginacion real en tablas
- [ ] Soporte multidivisa (selector en header)

### Fase 7: Integraciones
- [ ] Polygon.io (stocks, forex, indices)
- [ ] CoinGecko (crypto)
- [ ] FX rates (tasas de cambio para multidivisa)
- [ ] Solid Queue recurring jobs (actualizaciones periodicas)
- [ ] Circuit breakers (proteccion contra fallos de API externos)

---

## 9. Referencia Visual por Pagina

Cada subcarpeta contiene:
- `screen.png` - Captura del diseno visual
- `code.html` - Codigo HTML de referencia (Stitch)

### Paginas Publicas

| Pagina | Carpeta | Descripcion |
|--------|---------|-------------|
| Landing Page | `landing_page_-_trendstocker/` | Hero + features + stats + CTA + footer |
| Login/Registro | `acceso_y_registro_-_trendstocker/` | Card split: branding izq + form der (Login/Register tabs, email/password) |
| Trend Explorer | `trendstocker_dashboard/` | Barra filtros oscura + stock detail (OKE) + metricas + chart SVG + trend score 94/100 |
| Open Source | `open_source_project/` | Hero + terminal mockup + why OSS + contributing guide + hall of fame |
| Privacy Policy | `privacy_policy/` | TOC sidebar + 7 secciones (Introduction, Collection, Usage, Storage, Rights, Cookies, Contact) |
| Terms of Service | `terms_of_service/` | TOC sidebar + 7 secciones + TL;DR + Accept/Decline buttons |
| Risk Disclosure | `risk_disclosure/` | TOC sidebar + 5 secciones + warning boxes + Accept/Decline buttons |

### Paginas de Usuario Autenticado

| Pagina | Carpeta | Descripcion |
|--------|---------|-------------|
| Dashboard | `dashboard_principal_-_trendstocker/` | 4 KPIs + watchlist table + news feed + trending sidebar + market status. Soporte multidivisa con selector divisa (USD/EUR/MXN) en header |
| Market Explorer | `explorador_de_mercado_-_trendstocker/` | 4 index cards + filtros avanzados + tabla paginada (4,821 results) + Export CSV |
| Portfolio | `gestión_de_portafolio_-_trendstocker/` | 3 KPIs + donut allocation + tabs (Open/Closed/Dividends) + positions table. Soporte multidivisa con columna currency + domestic/international split + FX rates |
| Alertas | `alertas_de_tendencia_-_trendstocker/` | Create form + rules table + live feed sidebar (LIVE badge) + delivery prefs |
| Earnings | `calendario_de_earnings_-_trendstocker/` | Watchlist priority sidebar + calendar grid mensual + BMO/AMC badges + pro tips |
| Mi Perfil | `mi_perfil_-_trendstocker/` | Avatar + badges + personal info form + account settings toggles + watchlist |

### Paginas de Administrador

| Pagina | Carpeta | Descripcion |
|--------|---------|-------------|
| Gestion Activos | `admin:_gestión_de_activos/` | 3 KPIs + tabs All/Stocks/Crypto + asset table con toggle status + paginacion |
| Logs Sistema | `admin:_logs_de_sistema/` | Filtros (severity/module/time) + log table con badges + 4 stats + auto-refresh |
| Usuarios/Integ. | `admin:_usuarios_e_integraciones/` | User table (status badges) + Integration cards (API key, sync status) + Add Provider |

### Componentes Compartidos

| Componente | Carpeta | Descripcion |
|-----------|---------|-------------|
| Onboarding Wizard | `designs/shared/onboarding/` | 3 pasos: mercados, stocks, exito (screen-step1/2/3.png) |
| Empty States | `designs/shared/empty-states/` | Coleccion de estados vacios para todas las vistas |
| Notification Panel | `designs/shared/notification-panel/` | Dropdown de notificaciones con badge |
| News Feed | `designs/shared/news-feed/` | Feed de noticias con filtros y trending |
| Global Search | `designs/shared/global-search/` | Dropdown overlay con busqueda agrupada |
| Error Pages | `designs/shared/error-pages/` | 404 y 500 con branding (screen-404/500.png) |

### Paginas Publicas Adicionales

| Pagina | Carpeta | Descripcion |
|--------|---------|-------------|
| Forgot Password | `designs/public/forgot-password/` | Formulario de email para solicitar reset |
| Reset Password | `designs/public/reset-password/` | Formulario de nueva password con token |

---

## Notas Tecnicas

- **CSS Framework:** Tailwind CSS (via CDN en los disenos, migrar a build en Rails)
- **Iconos:** Material Symbols Rounded (Google Fonts)
- **Tipografia:** Inter (Google Fonts)
- **Color primario:** `#004a99` (azul oscuro) - usar como `primary` en Tailwind config
- **Graficos:** Sparklines hechos con CSS/SVG inline (no requieren libreria JS externa inicialmente)
- **Donut chart:** Hecho con `conic-gradient` CSS
- **Responsive:** Mobile-responsive desde Fase 1 usando breakpoints de Tailwind.
- **Dark mode:** Los HTMLs incluyen clases de dark mode en Tailwind, implementar con toggle
- **Licencia:** Este proyecto es 100% open source. No hay tiers premium ni pricing.

---

## Documentos Referenciados

| Documento | Descripcion |
|-----------|-------------|
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | Definicion completa de modelos, migraciones, seeds y ERD |
| [SUGGESTIONS.md](SUGGESTIONS.md) | Sugerencias de mejora y notas de implementacion |
