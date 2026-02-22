# Stockerly — Roadmap de Implementacion

> Estado actual del proyecto y fases restantes.
> Cada fase es auto-contenida: incluye que documentos revisar, que construir, que testear y que commits crear.
>
> **Catalogo de paginas:** [docs/CATALOG.md](docs/CATALOG.md) — indice maestro con estado de cada pantalla
> **Workflow:** [docs/WORKFLOW.md](docs/WORKFLOW.md) — proceso para agregar nuevas pantallas

---

## Estado de Fases

| Fase | Nombre | Estado | Specs |
|------|--------|--------|-------|
| 0 | Setup Base | Completada | - |
| 1 | Paginas Publicas | Completada | ~20 |
| 2 | Autenticacion | Completada | ~57 |
| 3 | Zona Autenticada (6 paginas estaticas) | Completada | ~69 |
| 4 | Panel Admin (3 paginas estaticas) | Completada | 85 |
| 4.5 | Auditoria de Consistencia + System Tests | Completada | 106 |
| 4.6 | Componentes Compartidos (8 pantallas nuevas) | Completada | 94 |
| 5 | Modelos, Migraciones y Seeds | Completada | 301 |
| 6 | Backend (Use Cases, Events, CRUD) | Completada | 490 |
| 6.5 | Auditoria de Consistencia e Integracion | Completada | 540 |
| 7 | Integraciones Externas | Completada | 654 |
| **8** | **Polish & Completeness** | **Completada** | 702 |

---

## Fase 4.5: Auditoria de Consistencia + System Tests

### Objetivo
Antes de conectar el backend, verificar que todo el frontend estatico (16 paginas) es consistente, coherente y funcional. Detectar y corregir problemas de branding, datos, navegacion, dark mode y responsive. Agregar system specs con Capybara para garantizar que Stimulus controllers y flujos de navegacion funcionan.

### Documentos a Revisar
- `docs/spec/README.md` sec. 9 (Referencia Visual por Pagina — comparar contra implementacion)
- `designs/{zona}/{pagina}/screen.png` — Comparar cada pagina renderizada contra el diseno original
- `docs/CATALOG.md` — Estado de implementacion de cada pagina
- `CLAUDE.md` — Branding oficial ("Stockerly" en el producto)

### Pasos

#### 4.5.1 — Auditoria de Branding
- Revisar todas las vistas por inconsistencias "TrendStocker" vs "Stockerly"
- El producto se llama **Stockerly** en toda la UI visible al usuario
- Verificar: titles, navbars, sidebars, footers, meta tags
- Corregir cualquier inconsistencia encontrada
- **Commit:** `Fix branding consistency across all views`

#### 4.5.2 — Auditoria de Datos Hardcodeados
- Verificar que los datos son coherentes entre paginas:
  - Dashboard watchlist y Profile watchlist usan los mismos 6 stocks
  - Market listings incluyen los stocks del watchlist
  - Precios son consistentes (AAPL $189.43 en todos lados)
  - Admin assets incluyen assets que aparecen en zona autenticada
- Corregir discrepancias
- **Commit:** `Harmonize hardcoded data across all views`

#### 4.5.3 — Auditoria de Links y Navegacion
- Verificar que todos los enlaces de navegacion apuntan a rutas reales (no `#`)
- Verificar que sidebar admin, navbar app, navbar publica son coherentes
- Verificar que breadcrumbs son correctos en admin
- Verificar que logo links van al lugar correcto (public→root, app→dashboard, admin→admin/assets)
- **Commit:** `Fix navigation links and remove placeholder hrefs`

#### 4.5.4 — Auditoria de Dark Mode
- Revisar que todas las vistas tienen clases `dark:` en:
  - Fondos (bg-white → dark:bg-slate-900)
  - Textos (text-slate-900 → dark:text-white)
  - Bordes (border-slate-200 → dark:border-slate-800)
  - Inputs y selects
- Verificar componentes compartidos (stat_card, status_badge, etc.)
- **Commit:** `Ensure dark mode classes on all views and components` (si hay correcciones)

#### 4.5.5 — Setup Capybara + System Specs
- Configurar Capybara en `spec/support/` si no existe
- Verificar que Selenium/headless Chrome esta disponible
- Agregar `spec/system/` con system specs:

**Flujos a cubrir:**

| Test | Que verifica |
|------|-------------|
| Navegacion publica | Landing → nav links → Trends, Open Source, Legal pages |
| Flujo auth completo | Register → redirect a dashboard → Logout → Login → Dashboard |
| Navegacion autenticada | Navbar links llevan a las 6 paginas, cada una carga ok |
| Stimulus: tabs | Portfolio tabs (Open/Closed/Dividends) cambian de panel |
| Stimulus: toggle | Profile toggles cambian estado visual |
| Stimulus: calendar_nav | Earnings month nav actualiza texto del mes |
| Admin sidebar | Sidebar links llevan a Assets, Logs, Users |
| Admin tabs | Asset tabs (All/Stocks/Crypto) cambian de panel |
| Guard: zona auth | Acceder a /dashboard sin login redirige a /login |
| Guard: zona admin | User normal accede a /admin/assets → redirige a root |

- **Commit:** `Add system specs with Capybara for navigation and Stimulus controllers`

#### 4.5.6 — Auditoria Visual (manual)
- Levantar `rails server` y recorrer las 16 paginas
- Comparar lado a lado contra `designs/{zona}/{pagina}/screen.png`
- Documentar diferencias significativas como issues en un checklist
- Corregir lo critico, anotar lo cosmetico para futuro
- **Commit:** `Fix visual discrepancies found during manual audit` (si hay correcciones)

### Verificacion Final
```bash
bundle exec rspec                    # Todos verdes (85 request + ~10 system)
bundle exec rspec spec/system/       # System specs verdes
rails server                         # Verificacion visual manual OK
```

---

## Fase 4.6: Componentes Compartidos (6 pantallas nuevas)

### Objetivo
Implementar las 6 pantallas/componentes nuevos identificados por los expertos en `docs/spec/SUGGESTIONS.md`. Estas pantallas ya tienen diseno de referencia en `designs/shared/` y SPEC.md con metadatos completos.

### Documentos a Revisar
- `designs/shared/*/SPEC.md` — Spec de cada componente nuevo
- `designs/shared/*/screen.png` — Diseno de referencia de Stitch
- `docs/spec/SUGGESTIONS.md` sec. 2 (Product Strategist) y sec. 4 (UX Designer) — Justificacion y requisitos
- `docs/CATALOG.md` — Pantallas #20-25 (estado actual: D)

### Pantallas nuevas

| # | Componente | SPEC | Diseno | Prioridad |
|---|-----------|------|--------|-----------|
| 20 | Onboarding Wizard (3 pasos) | [SPEC](designs/shared/onboarding/SPEC.md) | 3 screens | Critica |
| 21 | Empty States Collection | [SPEC](designs/shared/empty-states/SPEC.md) | 1 screen | Critica |
| 22 | Notification Panel | [SPEC](designs/shared/notification-panel/SPEC.md) | 1 screen | Alta |
| 23 | News Feed Page | [SPEC](designs/shared/news-feed/SPEC.md) | 1 screen | Media |
| 24 | Global Search Dropdown | [SPEC](designs/shared/global-search/SPEC.md) | 1 screen | Media |
| 25 | Error Pages (404/500) | [SPEC](designs/shared/error-pages/SPEC.md) | 2 screens | Baja |

### Pasos

#### 4.6.1 — Empty States (partial reutilizable)
- Crear `app/views/components/_empty_state.html.erb` con params: icon, title, description, cta_text, cta_path
- Integrar en las 6 vistas existentes: Dashboard (watchlist, news), Portfolio, Alerts (rules, feed), Earnings, Profile
- Usar los textos y CTAs definidos en `designs/shared/empty-states/SPEC.md`
- **Test:** Request specs verifican empty state cuando no hay datos
- **Commit:** `Add reusable empty state component and integrate in all views`
- **Actualizar:** CATALOG.md #21 → H

#### 4.6.2 — Error Pages
- Crear `public/404.html` y `public/500.html` basados en `designs/shared/error-pages/`
- HTML standalone (inline CSS, sin asset pipeline)
- Branding Stockerly, links a Dashboard y Home
- **Commit:** `Add custom 404 and 500 error pages with Stockerly branding`
- **Actualizar:** CATALOG.md #25 → H

#### 4.6.3 — Forgot/Reset Password (actualizar vistas existentes)
- Las vistas ya existen y funcionan (`password_resets/new.html.erb`, `password_resets/edit.html.erb`)
- Actualizar estilos para coincidir con los nuevos disenos Stitch en `designs/public/forgot-password/` y `designs/public/reset-password/`
- Agregar: password strength indicator, show/hide toggle, inline validation states
- **Commit:** `Update forgot/reset password views to match Stitch designs`

#### 4.6.4 — Onboarding Wizard (3 pasos)
- Crear `OnboardingController` con actions: `step1`, `step2`, `step3`, `complete`
- Agregar rutas: `GET/POST /onboarding/step1`, `GET/POST /onboarding/step2`, `GET /onboarding/step3`
- Crear 3 vistas basadas en `designs/shared/onboarding/screen-step{1,2,3}.png`
- Paso 1: seleccion de mercados (grid de cards seleccionables)
- Paso 2: seleccion de stocks populares (lista con boton +, min 3)
- Paso 3: resumen y "Go to Dashboard"
- Trigger: redirect post-registro cuando user no tiene watchlist items
- Stimulus: `onboarding-controller` (selection tracking, validation)
- **Test:** Request specs para flujo completo
- **Commit:** `Add onboarding wizard with 3-step flow for new users`
- **Actualizar:** CATALOG.md #20 → H

#### 4.6.5 — Notification Panel (dropdown overlay)
- Crear partial `app/views/shared/_notification_panel.html.erb`
- Integrar en `_app_navbar.html.erb` (dropdown desde icono campana)
- Datos hardcodeados: 6 notificaciones de ejemplo (4 unread, 2 read)
- Badge con count en icono de campana
- Stimulus: `notification-controller` (toggle dropdown, mark as read)
- **Commit:** `Add notification panel dropdown in app navbar`
- **Actualizar:** CATALOG.md #22 → H

#### 4.6.6 — Global Search (dropdown overlay)
- Crear partial `app/views/shared/_global_search.html.erb`
- Integrar en `_app_navbar.html.erb` (expandir search bar)
- Datos hardcodeados: resultados de ejemplo agrupados (Stocks, News, Quick Actions)
- Stimulus: `search-controller` (toggle, debounce, keyboard nav, Cmd+K)
- **Commit:** `Add global search dropdown in app navbar`
- **Actualizar:** CATALOG.md #24 → H

#### 4.6.7 — News Feed Page
- Crear `NewsController#index` y ruta `GET /news`
- Crear vista `app/views/news/index.html.erb` basada en `designs/shared/news-feed/screen.png`
- Datos hardcodeados: articulos de ejemplo, filtros visuales
- Layout `app` (requiere autenticacion)
- Actualizar navbar app para incluir link a News (o accesible desde avatar dropdown)
- **Commit:** `Add news feed page with static content`
- **Actualizar:** CATALOG.md #23 → H

### Verificacion Final
```bash
bundle exec rspec                    # Todos verdes (85 + nuevos)
rails server                         # Verificar: onboarding flow, empty states, notifications, search, news, error pages
```

---

## Fase 5: Modelos, Migraciones y Seeds

### Objetivo
Crear toda la capa de datos: 21 migraciones nuevas (User y RememberToken ya existen), 21 modelos con validaciones/asociaciones/scopes, y seeds con datos realistas. Al finalizar, `rails db:migrate db:seed` corre sin errores y las vistas siguen funcionando.

### Documentos a Revisar
- `docs/spec/README.md` sec. 7 (Propuesta de Modelado) y sec. 8 (Fases)
- `docs/spec/DATABASE_SCHEMA.md` completo (23 migraciones, 23 modelos, seeds)
- `docs/spec/COMMANDS.md` sec. 1-2 (arquitectura, estructura de carpetas)
- `docs/spec/TECHNICAL_SPEC.md` sec. 1 (gems por agregar: dry-types, dry-struct, dry-validation, dry-monads, pagy, money-rails)

### Pasos

#### 5.1 — Dependencias
- Agregar gems al Gemfile: `dry-types`, `dry-struct`, `dry-validation`, `dry-monads`, `pagy`, `money-rails`
- `bundle install`
- Crear `app/types/types.rb` con dry-types compartidos
- **Test:** `bundle exec rspec` — 85 specs siguen verdes
- **Commit:** `Add dry-rb, pagy and money-rails gems with Types module`

#### 5.2 — Migraciones (21 tablas nuevas)
- Crear migraciones siguiendo DATABASE_SCHEMA.md sec. 2 exactamente:
  - Assets, Portfolios, Positions, Trades, WatchlistItems
  - AlertRules, AlertEvents, AlertPreferences
  - EarningsEvents, NewsArticles, MarketIndices, TrendScores
  - SystemLogs, Integrations
  - PortfolioSnapshots, FxRates, AssetPriceHistories
  - Notifications, AuditLogs, Dividends, DividendPayments
- Actualizar migracion de Users existente si faltan columnas (`avatar_url`, `is_verified`, `preferred_currency`)
- `rails db:migrate`
- **Test:** `rails db:migrate:status` muestra todas up, `bundle exec rspec` sigue verde
- **Commit:** `Add 21 database migrations for all domain models`

#### 5.3 — Modelos ActiveRecord (21 nuevos)
- Crear cada modelo siguiendo DATABASE_SCHEMA.md sec. 3 exactamente:
  - Enums, asociaciones, validaciones, scopes, metodos de instancia
  - Actualizar `User` model con asociaciones faltantes (has_one :portfolio, has_many :watchlist_items, etc.)
- **Tests unitarios:** Spec por cada modelo que verifique:
  - Validaciones (presencia, unicidad, formato)
  - Enums (valores correctos)
  - Asociaciones (belongs_to, has_many)
  - Scopes clave
- **Commit:** `Add 21 ActiveRecord models with validations, associations and scopes`

#### 5.4 — Seeds
- Crear `db/seeds.rb` siguiendo DATABASE_SCHEMA.md sec. 4 exactamente
- Incluir: 4 users, 10 assets, trades+positions para Alex, watchlist, alert rules/events, market indices, trend scores, earnings events, news articles, portfolio snapshots, FX rates, dividends, notifications, system logs, audit logs, integrations
- `rails db:seed`
- **Test:** `rails db:seed` corre sin errores, verificar conteos con `rails runner`
- **Commit:** `Add comprehensive seed data with realistic financial records`

#### 5.5 — Tests de Modelos
- `spec/models/` con un spec por modelo (21 archivos)
- Cubrir: factory validity, validaciones, enums, asociaciones, scopes, metodos clave
- **Commit:** `Add model specs for all 21 new domain models`

### Verificacion Final
```bash
bundle exec rspec          # Todos verdes (85 existentes + ~100 nuevos)
rails db:migrate:status    # Todas las migraciones up
rails db:seed              # Sin errores
```

---

## Fase 6: Backend (Use Cases, Events, CRUD)

### Objetivo
Conectar las vistas estaticas al backend real. Reemplazar datos hardcodeados por datos de BD. Implementar Use Cases con dry-monads, Domain Events, Contracts, y Turbo Streams para interactividad.

### Documentos a Revisar
- `docs/spec/COMMANDS.md` completo (30+ Use Cases, Events, Contracts, Domain Services, Event Handlers, Gateways)
- `docs/spec/TECHNICAL_SPEC.md` sec. 2-5 (arquitectura hexagonal, Hotwire, Stimulus)
- `docs/spec/README.md` sec. 5 (Controllers y Vistas — contenido esperado por pagina)
- `docs/spec/DATABASE_SCHEMA.md` sec. 3 (metodos de modelo que se usan en Use Cases)

### Pasos

#### 6.1 — Infraestructura DDD
- Crear base classes: `ApplicationUseCase`, `ApplicationContract`, `BaseEvent`, `EventBus`
- Crear `ProcessEventJob` para handlers async via Solid Queue
- Crear initializer `config/initializers/event_subscriptions.rb`
- **Test:** Specs para EventBus (subscribe, publish, async dispatch)
- **Commit:** `Add DDD infrastructure: Use Case base, EventBus, Contracts`

#### 6.2 — Domain Services y Value Objects
- `app/domain/portfolio_summary.rb` — Calcula KPIs de portfolio
- `app/domain/alert_evaluator.rb` — Evalua condiciones de alertas contra precios
- `app/domain/market_sentiment.rb` — Sentimiento basado en trend scores
- `app/domain/gain_loss.rb` — Value Object: absolute + percent
- `app/domain/alert_condition.rb` — Value Object: condition + threshold
- **Test:** Specs unitarios para cada domain service
- **Commit:** `Add domain services: PortfolioSummary, AlertEvaluator, MarketSentiment`

#### 6.3 — Identity Use Cases (Auth ya existe, agregar profiles)
- `Profiles::UpdateInfo` + `Profiles::ChangePassword`
- Contracts: `Profiles::UpdateContract`, `Profiles::ChangePasswordContract`
- Events: `ProfileUpdated`, `PasswordChanged`
- Event Handlers: `InvalidateSessionsOnPasswordChange`
- Conectar `ProfilesController#update` al Use Case
- **Test:** Specs para Use Cases + request specs para profile update
- **Commit:** `Add profile Use Cases: UpdateInfo, ChangePassword with events`

#### 6.4 — Trading Use Cases (Dashboard, Portfolio, Watchlist)
- `Dashboard::Assemble` — Carga todos los datos del dashboard
- `Portfolio::LoadOverview` — Posiciones, allocation, dividendos
- `Trades::ExecuteTrade` + `Positions::OpenPosition` + `Positions::ClosePosition`
- `Watchlist::AddAsset` + `Watchlist::RemoveAsset`
- `Snapshots::TakePortfolioSnapshot`
- Events: `TradeExecuted`, `PositionOpened`, `PositionClosed`, `WatchlistItemAdded`, `PortfolioSnapshotTaken`
- Handlers: `RecalculateAvgCostOnTrade`, `LogTradeActivity`
- Conectar controllers: Dashboard, Portfolio, Watchlist (nuevo controller)
- Reemplazar datos hardcodeados en vistas con datos de BD
- **Test:** Specs para cada Use Case + request specs actualizados
- **Commit:** `Add Trading Use Cases: Dashboard, Portfolio, Trades, Watchlist`

#### 6.5 — Alerts Use Cases
- `Alerts::CreateRule`, `UpdateRule`, `ToggleRule`, `DestroyRule`
- `Alerts::UpdatePreferences`, `EvaluateRules`
- Contracts: `Alerts::CreateContract`, `UpdateContract`, `PreferencesContract`
- Events: `AlertRuleCreated`, `AlertRuleTriggered`
- Handlers: `CreateAlertEventOnTrigger`, `CreateNotificationOnAlert`
- Conectar `AlertsController` CRUD con Turbo Streams
- **Test:** Specs para Use Cases + request specs para CRUD
- **Commit:** `Add Alerts Use Cases: CRUD rules, evaluate, preferences with Turbo Streams`

#### 6.6 — Market Data Use Cases
- `Market::ExploreAssets` + `Market::ExportCsv`
- `Earnings::ListForMonth`
- `Trends::LoadAssetTrend`
- Contracts: `Market::ExploreContract`
- Conectar controllers con filtros reales y paginacion (pagy)
- **Test:** Specs para Use Cases + request specs
- **Commit:** `Add Market Data Use Cases: ExploreAssets, Earnings, Trends with pagy`

#### 6.7 — Notifications
- `Notifications::CreateNotification` + `MarkAsRead`
- Events: `NotificationCreated`
- Handlers: `BroadcastNotification` (Turbo Streams)
- Nuevo `NotificationsController` con dropdown Turbo Frame
- **Test:** Specs para Use Cases
- **Commit:** `Add Notifications Use Cases with Turbo Stream broadcasts`

#### 6.8 — Admin Use Cases
- `Admin::Assets::CreateAsset`, `ToggleStatus`, `TriggerSync`
- `Admin::Users::SuspendUser`, `UpdateUser`
- `Admin::Integrations::ConnectProvider`, `RefreshSync`, `DisconnectProvider`
- `Admin::Logs::ListLogs`, `ExportCsv`
- Events: `UserSuspended`, `IntegrationConnected`
- Handlers: `SendSuspensionEmail`, `LogIntegrationConnected`, `CreateAuditLog`
- Conectar admin controllers con datos reales + Turbo Streams
- **Test:** Specs para Use Cases + request specs actualizados
- **Commit:** `Add Admin Use Cases: assets, users, integrations, logs`

#### 6.9 — Tests de Integracion
- Request specs end-to-end para flujos criticos:
  - Register → Dashboard con datos reales
  - Create alert → Evaluate → Notification generada
  - Execute trade → Position updated → Snapshot
  - Admin suspend user → Event → Email
- **Commit:** `Add end-to-end integration tests for critical flows`

### Verificacion Final
```bash
bundle exec rspec                    # Todos verdes (~200+ specs)
rails server                         # Vistas muestran datos de BD
# Verificar manualmente: dashboard, market, portfolio, alerts, earnings, admin
```

---

## Fase 6.5: Auditoria de Consistencia e Integracion

### Objetivo
Verificar que todo lo construido en fases 0-6 es consistente, bien integrado y testeable. Extraer logica inline de controllers a Use Cases, conectar vistas hardcodeadas a datos reales, documentar deuda tecnica con TODOs, y cerrar gaps de test coverage.

### Pasos Completados

#### 6.5.1 — Extraer logica inline de controllers a Use Cases
- 7 Use Cases nuevos: `Alerts::LoadDashboard`, `Notifications::ListRecent`, `Profiles::LoadProfile`, `Onboarding::LoadAssetCatalog`, `Onboarding::LoadProgress`, `Admin::Assets::ListAssets`, `Admin::Users::ListUsers`
- 4 auth controllers anotados con `# TODO:` definiendo la interfaz futura del Use Case

#### 6.5.2 — Corregir bugs monadicos
- `SuspendUser`: agregar `yield` antes de `publish()` para propagar fallos del EventBus
- `CompleteWizard`: rescue `ActiveRecord::RecordInvalid` → `Failure(:validation)`
- `UpdatePreferences`: rescue `ActiveRecord::RecordInvalid` → `Failure(:validation)`

#### 6.5.3 — Conectar vistas hardcodeadas a datos reales
- Notification panel conectado a modelo `Notification` con badge dinamico
- Global search usa route helpers en vez de paths absolutos
- Onboarding step2/step3 cargan assets y progreso desde BD

#### 6.5.4 — Documentar botones sin funcionalidad
- 12 botones/elementos anotados con `# TODO:` especificando el Use Case target

#### 6.5.5 — Cerrar gaps de test coverage
- 4 specs faltantes: `UpdateRule`, `UpdatePreferences`, `CreateContract`, `NotificationsController`
- 7 specs para Use Cases nuevos del paso 6.5.1

#### 6.5.6 — Tests de integracion E2E
- 11 request specs verificando flujos refactorizados de punta a punta

### Verificacion Final
```bash
bundle exec rspec                    # 540 specs, 0 failures
                                     # Line Coverage: 96.88%
                                     # Branch Coverage: 79.63%
```

---

## Fase 7: Integraciones Externas

### Objetivo
Conectar con APIs externas para datos de mercado en tiempo real. Implementar gateways, jobs recurrentes, circuit breakers y Turbo Streams para actualizaciones live.

### Documentos a Revisar
- `docs/spec/COMMANDS.md` sec. 8 (Gateways: Polygon, CoinGecko, FX Rates)
- `docs/spec/TECHNICAL_SPEC.md` sec. 1 (Solid Queue, Solid Cable)
- `docs/spec/DATABASE_SCHEMA.md` sec. 3.15 (Integration model con encrypted API keys)
- `docs/spec/README.md` sec. 8 (Fase 7 checklist)

### Pasos

#### 7.1 — Gateway Infrastructure
- Crear `MarketDataGateway` (interface base)
- Crear `PolygonGateway` (adapter: Faraday + Polygon.io REST API)
- Crear `CoingeckoGateway` (adapter: CoinGecko REST API)
- Crear `FxRatesGateway` (adapter: exchangerate-api.com)
- Configurar credentials Rails para API keys
- **Test:** Specs con WebMock/VCR para cada gateway
- **Commit:** `Add market data gateways: Polygon.io, CoinGecko, FX Rates`

#### 7.2 — Background Jobs (Solid Queue)
- `SyncAllAssetsJob` — Actualiza precios de todos los assets activos
- `SyncSingleAssetJob` — Actualiza precio de un asset especifico
- `SyncIntegrationJob` — Refresh de integracion especifica
- `TakeSnapshotsJob` — Portfolio snapshots diarios
- `RefreshFxRatesJob` — Tasas de cambio
- `ProcessEventJob` — Procesar events async
- Configurar Solid Queue recurring schedule
- **Test:** Specs para cada job
- **Commit:** `Add background jobs for price sync, snapshots and FX rates`

#### 7.3 — Real-time Updates (Turbo Streams + Solid Cable)
- `AssetPriceUpdated` event → `BroadcastPriceUpdate` handler
- Turbo Stream channels: `asset_{id}`, `notifications_{user_id}`
- Partials para broadcast: `_asset_price`, `_notification`, `_notification_badge`
- ActionCable subscription en vistas (Dashboard, Market, Portfolio)
- **Test:** Specs para broadcast handlers
- **Commit:** `Add real-time price updates via Turbo Streams and ActionCable`

#### 7.4 — Circuit Breakers y Resilencia
- Circuit breaker pattern para cada gateway (basado en errores consecutivos)
- Retry logic con exponential backoff
- Fallback a ultimo precio conocido cuando API falla
- Rate limiting en API calls (respetar limites de Polygon/CoinGecko)
- Logging de errores de gateway en SystemLog
- **Test:** Specs para circuit breaker logic
- **Commit:** `Add circuit breakers and resilience patterns for external APIs`

#### 7.5 — Admin: Gestion de Integraciones
- Conectar UI de integraciones con gateways reales
- Test de conectividad desde admin panel
- Logs de sincronizacion en SystemLog
- **Test:** Request specs para admin integration management
- **Commit:** `Connect admin integration management to real gateways`

#### 7.6 — Tests de Integracion Final
- Tests end-to-end con mocks de APIs externas
- Verificar: sync → prices updated → alerts evaluated → notifications sent → UI updated
- Performance: verificar N+1 queries con bullet gem
- **Commit:** `Add integration tests for external API flows`

### Verificacion Final
```bash
bundle exec rspec                    # Todos verdes (~250+ specs)
rails server                         # Precios se actualizan en real-time
# Verificar: Solid Queue dashboard, Turbo Stream updates, circuit breaker logging
```

---

## Fase 8: Polish & Completeness

### Objetivo
Resolver los 16 TODOs pendientes en el codigo: extraer logica inline de auth controllers a Use Cases, conectar botones UI, y deshabilitar features post-launch. Dejar 0 deuda tecnica anotada.

### Pasos Completados

#### 8.1 — Identity Use Cases
- 4 Use Cases nuevos: `Identity::Register`, `Identity::Login`, `Identity::RequestPasswordReset`, `Identity::ResetPassword`
- 4 Contracts con validacion dry-validation
- 3 auth controllers refactorizados para delegar al Use Case (session/cookie management queda en controller)

#### 8.2 — Admin Log Tools
- `Admin::Logs::ExportCsv` Use Case con generacion CSV y evento CsvExported
- Filtros conectados via `form_with` (search, severity, module)
- Botones Export CSV y Force Refresh conectados a endpoints reales

#### 8.3 — UI Button Connections
- Profile Email Notifications toggle conectado a `Alerts::UpdatePreferences` via PATCH
- Edit Settings → anchor link a #account-settings
- Buy/Sell y Add Position → link a Market page
- Setup Alerts → link a alerts_path
- `Admin::Integrations::ConnectProvider` Use Case con formulario inline
- Privacy Mode toggle deshabilitado (sin campo en BD)

#### 8.4 — Post-Launch Cleanup
- Share Profile, View Full Report, Subscribe Now → disabled con "Coming soon"
- 0 TODOs restantes en app/

### Verificacion Final
```bash
grep -r "TODO" app/ --include="*.rb" --include="*.erb" | wc -l  # 0
bundle exec rspec                    # 702 specs, 0 failures
                                     # Line Coverage: 94.18%
                                     # Branch Coverage: 75.48%
```

---

## Protocolo para Retomar Cualquier Fase

Al iniciar o retomar una fase:

1. **Revisar este ROADMAP.md** — Identificar en que paso de que fase te encuentras
2. **Leer los documentos indicados** en la seccion "Documentos a Revisar" de esa fase
3. **Revisar disenos** de referencia visual (`designs/{zona}/{pagina}/screen.png`) y SPEC.md cuando aplique
4. **Crear todo list** con los pasos de la fase para tracking de progreso
5. **Ejecutar `bundle exec rspec`** antes de empezar — confirmar que todo esta verde
6. **Implementar paso por paso** — un commit por paso, tests incluidos
7. **Actualizar todo list** al completar cada paso
8. **Ejecutar `bundle exec rspec`** despues de cada commit — mantener verde siempre

### Convencion de Commits
- Un commit por paso logico (no por archivo)
- Incluir tests en el mismo commit que el codigo que testean
- Mensaje descriptivo en ingles, cuerpo opcional en espanol
- Co-authored-by con Claude

### Convencion de Tests
- **Model specs:** `spec/models/` — validaciones, enums, asociaciones, scopes
- **Use Case specs:** `spec/use_cases/` — happy path, validacion, edge cases
- **Request specs:** `spec/requests/` — smoke tests, guards, flujos CRUD
- **Helper specs:** `spec/helpers/` — helpers con logica
- **Controller specs:** `spec/controllers/` — solo para before_actions complejos
- **Domain specs:** `spec/domain/` — domain services y value objects
