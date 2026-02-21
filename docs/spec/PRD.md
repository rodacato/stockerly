# Stockerly - Product Requirements Document (PRD)

> **Version:** 1.1
> **Producto:** Stockerly — Plataforma de analisis de tendencias y gestion de portafolios de inversion
> **Stack:** Rails 8.1.2 · PostgreSQL · Hotwire · Tailwind CSS 4 · dry-rb
> **Arquitectura:** DDD · Hexagonal (Ports & Adapters) · Event-Driven
>
> **Documentos relacionados:**
> - [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) — Especificacion tecnica y arquitectura
> - [COMMANDS.md](COMMANDS.md) — Use Cases, Domain Events, Bounded Contexts
> - [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) — Modelado de BD
> - [EXPERTS.md](EXPERTS.md) — Panel de expertos
> - [README.md](README.md) — Mapa de paginas y layouts
> - [SUGGESTIONS.md](SUGGESTIONS.md) — Sugerencias y mejoras propuestas

---

## 1. Vision del Producto

Stockerly es una plataforma web que permite a traders e inversionistas monitorear tendencias de mercado, gestionar portafolios multi-divisa, configurar alertas inteligentes y consultar calendarios de earnings — todo desde un dashboard unificado con datos en tiempo real.

El producto se posiciona como una herramienta open-source, transparente y community-driven, orientada tanto a traders individuales como a inversionistas casuales.

---

## 2. Usuarios Objetivo

| Persona | Descripcion | Necesidades |
|---------|-------------|-------------|
| **Trader Activo** | Opera diariamente, necesita datos en tiempo real | Dashboard rapido, alertas instantaneas, trend scores |
| **Inversionista Casual** | Revisa su portafolio semanalmente | Vista de portafolio clara, ganancias/perdidas, earnings |
| **Administrador** | Gestiona la plataforma | CRUD de activos, monitoreo de sistema, gestion de usuarios |

---

## 3. Roles y Permisos

| Rol | Acceso | Descripcion |
|-----|--------|-------------|
| **Visitante** | Zona publica | Landing, trend explorer publico, paginas legales |
| **Usuario** | Zona autenticada | Dashboard, portafolio, alertas, earnings, perfil |
| **Admin** | Panel de administracion | Gestion de activos, usuarios, integraciones, logs de sistema |

---

## 4. Funcionalidades por Modulo

### 4.1 Zona Publica

#### F-001: Landing Page
- **Descripcion:** Pagina de aterrizaje que presenta la propuesta de valor del producto
- **Elementos:**
  - Hero section con CTA "Get Started Now" y "Explore Markets"
  - Social proof: "50,000+ traders joined this month"
  - Logos de instituciones confiables
  - 3 feature cards: Trend Analysis, Portfolio Management, Smart Alerts
  - Barra de estadisticas: $4.2B Assets Tracked, 50K+ Traders, 99.9% Uptime, 24/7 Monitoring
- **Criterios de aceptacion:**
  - La pagina carga en < 2 segundos
  - Los CTAs redirigen a registro
  - Totalmente responsive

#### F-002: Autenticacion (Login / Registro)
- **Descripcion:** Sistema de acceso con email/password
- **Elementos:**
  - Card dividida: branding izquierdo + formulario derecho
  - Toggle Login / Create Account
  - Formulario: email, password
  - "Remember me for 30 days"
  - "Forgot password?" link
  - Texto legal con links a Terms y Privacy
- **Criterios de aceptacion:**
  - Login con email/password funcional (Rails `has_secure_password`)
  - Registro crea usuario
  - Sesion persiste con cookie segura
  - Redireccion post-login a dashboard
  - Social auth eliminado de v1 — solo email/password

#### F-002b: Password Reset
- **Descripcion:** Flujo de recuperacion de password
- **Elementos:**
  - "Forgot password?" link en login
  - Formulario de email para solicitar reset
  - Email de reset con token link
  - Formulario de nueva password
- **Criterios de aceptacion:**
  - Token expira en 2h
  - Token se invalida al usar
  - Rate limited

#### F-003: Trend Explorer Publico
- **Descripcion:** Vista publica de analisis de tendencias de un activo
- **Elementos:**
  - Barra de filtros: Trend Type, Price Range, % Change, Exchange, Industry
  - Tabs: Top Upward / Downward / Most Popular Trends
  - Detalle de stock: nombre, ticker, precio, % change, trend direction
  - Metricas: Market Cap, P/E, Div Yield, Volume, Shares Outstanding
  - Trend Score (0-100) con label descriptivo
  - Grafico de performance (SVG)
  - Info cards: Exchange, Industry, Next Earnings
- **Criterios de aceptacion:**
  - Accesible sin login
  - Datos hardcodeados inicialmente
  - Los filtros cambian la vista (via Turbo Frames)

#### F-004: Pagina Open Source
- **Descripcion:** Presentacion del proyecto como open source
- **Elementos:**
  - Hero con terminal mockup (git clone)
  - Why Open Source: Transparency, Innovation, No Lock-in
  - Guia de contribucion en 3 pasos
  - Stats del proyecto (stars, PRs, forks, contributors)
  - Hall of Fame de contribuidores
- **Criterios de aceptacion:**
  - Links a GitHub reales
  - Pagina estatica, sin datos dinamicos

#### F-005: Paginas Legales
- **Descripcion:** Privacy Policy, Terms of Service, Risk Disclosure
- **Elementos por pagina:**
  - Breadcrumbs de navegacion
  - Sidebar con Table of Contents (navegacion interna)
  - Contenido en secciones numeradas
  - Botones Accept/Decline (Terms y Risk)
  - Boton Print/Download PDF
  - Boton "Back to Top" flotante
- **Criterios de aceptacion:**
  - Navegacion TOC funcional con scroll suave (Stimulus)
  - Contenido estatico

---

### 4.2 Zona Autenticada — Dashboard

#### F-006: Dashboard Principal
- **Descripcion:** Panel central del usuario con resumen completo
- **Elementos:**
  - Saludo personalizado: "Welcome back, {nombre}"
  - Selector de divisa en header (USD/EUR/MXN)
  - 4 KPI cards: Total Balance, Day Gain/Loss, Buying Power, Market Sentiment
  - Watchlist Performance: tabla con ticker, precio, cambio %, trend sparkline
  - Relevant News: feed de 3+ articulos con imagen, ticker, fuente, tiempo
  - Trending Today (sidebar): tickers con cambio %
  - Weekly Insight: card con recomendacion
  - Market Status: indicadores Open/Closed por exchange
- **Criterios de aceptacion:**
  - KPIs se calculan desde posiciones del portafolio
  - Watchlist muestra assets agregados por el usuario
  - News hardcodeado inicialmente, luego via feed
  - Trending y Market Status hardcodeado inicialmente
  - Cambiar divisa actualiza KPIs via Turbo Frame (sin recarga)
  - Conversion con rates hardcodeados inicialmente
  - Todos los valores monetarios se convierten a la divisa seleccionada

---

### 4.3 Zona Autenticada — Mercado

#### F-008: Explorador de Mercado
- **Descripcion:** Herramienta de busqueda y exploracion de activos
- **Elementos:**
  - 4 Index cards: S&P 500, NASDAQ 100, DOW JONES, FTSE 100
  - Panel de filtros: texto, Sector, Market Cap, Volatility, Trend Strength (slider)
  - Tabla "Market Listings": Asset/Ticker, Price, Change 24h, Trend Strength (barra), 7D Sparkline, Action (star, chart)
  - Paginacion (4,821 resultados)
  - Botones Export CSV y Real-time Updates
- **Criterios de aceptacion:**
  - Filtros actualizan tabla via Turbo Frame
  - Paginacion via Turbo Frame (sin recarga completa)
  - Boton star agrega a watchlist (Turbo Stream)
  - Export CSV genera descarga real
  - Datos hardcodeados inicialmente

---

### 4.4 Zona Autenticada — Portafolio

#### F-009: Gestion de Portafolio
- **Descripcion:** Vista completa de inversiones del usuario con soporte multidivisa
- **Elementos:**
  - 3 KPI cards: Total Portfolio Value (+%), Unrealized Gain/Loss, Buying Power
  - Desglose Domestic vs International en KPI
  - Donut chart de allocation por sector (CSS conic-gradient)
  - Tabs: Open Positions (12), Closed Positions, Dividend History
  - Tabla de posiciones: Ticker, Shares, Avg Cost, Market Price, Market Value, Total Gain, Currency (USD/TWD) con badges
  - Nota de FX conversion con "Last FX Refresh"
  - Botones "Buy/Sell" y "Add Position"
- **Criterios de aceptacion:**
  - KPIs se calculan desde posiciones
  - Donut chart refleja distribution real
  - Tabs cambian contenido via Turbo Frame
  - Posiciones hardcodeadas inicialmente
  - Posiciones internacionales muestran valor original + convertido
  - FX rates hardcodeados inicialmente

---

### 4.5 Zona Autenticada — Alertas

#### F-011: Alertas de Tendencia
- **Descripcion:** Sistema de creacion y gestion de alertas de mercado
- **Elementos:**
  - Stats: Triggered Today (count), Active Rules (count)
  - Formulario "Create New Alert": Ticker, Condition (select), Threshold Value
  - Conditions disponibles: Price Crosses Above, Price Crosses Below, % Day Change, RSI Overbought, RSI Oversold
  - Tabla "Active Alert Rules": Symbol, Condition, Target, Status (Active/Paused), Actions (edit/delete/toggle)
  - Live Alert Feed (sidebar): timeline de eventos con badge LIVE pulsante
  - Delivery Preferences: checkboxes Browser Push, Email Digest, SMS Notifications
- **Criterios de aceptacion:**
  - Crear alerta agrega fila a tabla (Turbo Stream append)
  - Pausar/activar cambia status inline (Turbo Stream replace)
  - Eliminar remueve fila (Turbo Stream remove)
  - Live feed hardcodeado inicialmente, luego via ActionCable
  - Delivery preferences se guardan en BD

---

### 4.6 Zona Autenticada — Earnings

#### F-012: Calendario de Earnings
- **Descripcion:** Calendario visual de reportes financieros trimestrales
- **Elementos:**
  - Toggles: My Watchlist / All Markets
  - Navegador de mes (anterior/siguiente)
  - Sidebar "Watchlist Priority": lista de proximos earnings de assets seguidos
  - Calendario grid 7 columnas (Dom-Sab) con eventos
  - Eventos con badge BMO (Before Market Open) / AMC (After Market Close)
  - Estimated EPS por evento
  - Card "Earnings Pro Tips"
  - Leyenda de colores
- **Criterios de aceptacion:**
  - Cambiar mes actualiza calendario (Turbo Frame)
  - Toggle Watchlist/All filtra eventos (Turbo Frame)
  - Eventos de watchlist resaltados en azul
  - Datos hardcodeados inicialmente

---

### 4.7 Zona Autenticada — Perfil

#### F-013: Mi Perfil
- **Descripcion:** Pagina de informacion personal y configuracion de cuenta
- **Elementos:**
  - Header: avatar (128px), nombre, "Member since {fecha}"
  - Botones "Share Profile" y "Edit Settings"
  - Personal Information: form con Full Name y Email + Save Changes
  - Account Settings: toggles Email Notifications, Privacy Mode; links Change Password, Sign Out
  - My Watchlist: tabla con Asset, Price, Change 24h, Trend sparkline, Action delete
- **Criterios de aceptacion:**
  - Editar nombre/email actualiza sin recarga (Turbo Stream)
  - Toggles se guardan inmediatamente (Stimulus + fetch)
  - Eliminar de watchlist remueve fila (Turbo Stream)
  - Avatar editable (Active Storage)

---

### 4.8 Zona Admin

#### F-014: Gestion de Activos
- **Descripcion:** CRUD de activos financieros del sistema
- **Elementos:**
  - 3 KPI cards: Total Assets, Syncing Assets, Alerts (Action Needed)
  - Tabs: All Assets / Stocks / Crypto
  - Tabla: Asset Name, Symbol, Source, Status (Active/Disabled/Sync Issue), Actions (edit/toggle)
  - Paginacion
  - Botones "Manual Sync" y "Add Asset"
- **Criterios de aceptacion:**
  - Toggle status via Turbo Stream (inline)
  - Tabs filtran via Turbo Frame
  - Add Asset via modal o formulario inline
  - Paginacion via Turbo Frame

#### F-015: Logs de Sistema
- **Descripcion:** Visor de logs y operaciones del sistema
- **Elementos:**
  - Filtros: busqueda, Severity, Module, Time Range
  - Tabla: Status badge, Task Execution, Module, Timestamp, Duration, Action
  - 4 stats cards: Successful Tasks %, Active Alerts, Avg Run Time, Storage Used
  - Toggle Auto-refresh
  - Botones Export CSV, Force Refresh
- **Criterios de aceptacion:**
  - Filtros actualizan tabla (Turbo Frame)
  - Auto-refresh via Stimulus (polling cada 30s)
  - Export CSV genera descarga

#### F-016: Usuarios e Integraciones
- **Descripcion:** Gestion de usuarios y conectividad con proveedores de datos
- **Elementos:**
  - User Management: tabla con Profile, Join Date, Role (Usuario/Admin), Status (Active/Online/Suspended), Actions (menu)
  - Market Data Connectivity: cards de integraciones con provider, status badge, API key (oculta), last sync, botones Settings/Refresh Sync
  - Card "Add New Provider"
- **Criterios de aceptacion:**
  - Cambiar rol/status de usuario inline (Turbo Stream)
  - Suspender usuario cambia badge
  - API keys siempre enmascaradas en UI
  - Refresh Sync actualiza timestamp (Turbo Stream)

---

### 4.9 Zona Autenticada — Onboarding y UX

#### F-017: Onboarding Wizard
- **Descripcion:** Flujo de 3 pasos post-registro para activar al usuario
- **Elementos:**
  - Paso 1: Elegir intereses (sectores, tipos de activos)
  - Paso 2: Seleccionar 3-5 stocks para watchlist inicial
  - Paso 3: Tour guiado del dashboard
- **Criterios de aceptacion:**
  - Usuario se considera "activated" cuando tiene 3+ items en watchlist
  - Wizard se muestra solo en primer login post-registro
  - Se puede saltar pero se recuerda el estado incompleto

#### F-018: Empty States
- **Descripcion:** Todas las paginas deben tener disenos de estado vacio
- **Elementos:**
  - Ilustracion contextual por pagina
  - Texto descriptivo explicando que se vera cuando haya datos
  - CTA principal para la accion que popula la pagina (ej: "Add your first stock", "Create an alert")
- **Criterios de aceptacion:**
  - Cada vista autenticada tiene un empty state definido
  - El CTA del empty state lleva a la accion correcta
  - Consistencia visual entre todos los empty states

#### F-019: Notification System
- **Descripcion:** Sistema de notificaciones in-app via icono de campana en navbar
- **Elementos:**
  - Icono de campana en navbar con badge de conteo de no leidas
  - Dropdown con lista de notificaciones recientes
  - Modelo: Notification (user_id, title, body, read_at, notifiable_type, notifiable_id)
  - Integracion con alertas de tendencia (F-011) y earnings (F-012)
- **Criterios de aceptacion:**
  - Turbo Stream broadcast a navbar cuando llega nueva notificacion
  - Badge de conteo de no leidas se actualiza en tiempo real
  - Marcar como leida via click (Turbo Stream replace)
  - Dropdown se abre/cierra con Stimulus controller

#### F-020: News Feed
- **Descripcion:** Pagina dedicada a noticias de mercado filtradas por relevancia
- **Elementos:**
  - Feed de articulos de noticias financieras con imagen, titulo, fuente, fecha y ticker relacionado
  - Filtros por categoria: All News, Stocks, Crypto, Economy
  - Filtro por watchlist del usuario (solo noticias de assets seguidos)
  - Paginacion infinita (scroll to load more)
  - Sidebar con "Trending Topics" y "Most Read"
- **Criterios de aceptacion:**
  - Noticias se cargan desde modelo NewsArticle
  - Filtros actualizan feed via Turbo Frame (sin recarga)
  - Infinite scroll via Stimulus controller
  - Datos hardcodeados inicialmente, luego via feed externo

#### F-021: Global Search
- **Descripcion:** Busqueda global accesible desde la navbar (Cmd+K / click en search bar)
- **Elementos:**
  - Dropdown overlay con input de busqueda
  - Resultados agrupados por tipo: Assets, Alerts, News
  - Keyboard navigation (flechas arriba/abajo, Enter para seleccionar, Esc para cerrar)
  - Shortcut Cmd+K / Ctrl+K para abrir
  - Debounce de 300ms en el input
  - Resultados recientes y sugerencias populares cuando el input esta vacio
- **Criterios de aceptacion:**
  - Busqueda busca en Assets (symbol, name), AlertRules (asset_symbol), NewsArticles (title)
  - Resultados se actualizan via Turbo Frame conforme se escribe
  - Keyboard shortcuts funcionales
  - Maximo 5 resultados por categoria

#### F-022: Error Pages
- **Descripcion:** Paginas de error personalizadas (404 y 500) con branding Stockerly
- **Elementos:**
  - Ilustracion/icono contextual (404: brujula perdida, 500: engranaje roto)
  - Titulo y mensaje descriptivo amigable
  - Boton "Go to Dashboard" o "Go Home" segun estado de auth
  - Link "Contact Support"
  - Footer consistente con el resto del sitio
- **Criterios de aceptacion:**
  - Paginas estaticas servidas por Rails (public/404.html, public/500.html)
  - Consistentes con el sistema de diseno (colores, tipografia)
  - No alarmar al usuario, tono amigable

---

## 5. Requerimientos No Funcionales

### 5.1 Performance
- Paginas cargan en < 2s (Time to First Byte < 500ms)
- Navegacion interna via Turbo Drive (sin full reload)
- Turbo Frames para actualizaciones parciales
- Turbo Streams para mutaciones en tiempo real

### 5.2 Seguridad
- Autenticacion con `has_secure_password` (bcrypt)
- Sesiones con cookie segura (httponly, secure, samesite)
- CSRF protection (Rails default)
- Rate limiting en login (Rails 8 built-in)
- Validacion de inputs con dry-validation
- API keys encriptadas con Rails credentials
- Roles y permisos validados en cada request

### 5.3 Arquitectura
- **DDD con 5 Bounded Contexts:** Identity, Trading (incluye Watchlist), Alerts, Market Intelligence, Administration
- **Hexagonal (Ports & Adapters):** Use Cases (input ports), Repositories/Gateways (output ports), ActiveRecord/APIs (driven adapters)
- **Event-Driven:** Domain Events con EventBus para side effects desacoplados
- **Use Cases con dry-monads** Result (Success/Failure) para logica de negocio
- **Contracts con dry-validation** para validacion de input en la frontera del sistema
- **Value Objects con dry-struct** para conceptos de dominio (Money, GainLoss, etc.)
- **Controllers delgados:** solo coordinan HTTP <-> Use Case <-> Turbo response
- **Models delgados:** solo asociaciones, scopes, enums y validaciones de BD (driven adapters)

### 5.4 UX
- Feedback visual instantaneo en toda accion (Turbo + Stimulus)
- Flash messages con auto-dismiss
- Confirmacion antes de acciones destructivas
- Formularios con validacion inline
- Skeleton loaders en Turbo Frames (loading states)

---

## 6. Metricas de Exito (v1)

| Metrica | Objetivo |
|---------|----------|
| Todas las 25 vistas y componentes implementados | 100% |
| Navegacion entre paginas sin full reload | Turbo Drive activo |
| CRUD funcional (watchlist, alerts, profile) | Operaciones via dry-rb |
| Autenticacion completa | Login/register/logout/forgot |
| Panel admin funcional | Assets, Users, Logs operativos |
| Tests de operaciones | > 80% coverage en operations |

---

## 7. Fuera de Alcance (v1)

- Datos de mercado en tiempo real (API real de Polygon/CoinGecko)
- Social auth (Google, Apple)
- Notificaciones push reales (browser, SMS)
- Graficos interactivos con libreria JS (Chart.js, D3)
- Pricing/suscripciones (producto 100% open source)
- App movil
- Internacionalizacion (i18n)
- WebSocket para live feed de precios
