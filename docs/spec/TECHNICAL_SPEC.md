# Stockerly - Especificacion Tecnica

> Arquitectura DDD con Ports & Adapters (Hexagonal), Event-Driven, Hotwire y dry-rb sobre Rails 8.1.2.
>
> **Documentos relacionados:**
> - [COMMANDS.md](COMMANDS.md) — Catalogo completo de Use Cases, Domain Events, Gateways y Bounded Contexts
> - [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) — Modelado de BD, migraciones y seeds
> - [EXPERTS.md](EXPERTS.md) — Panel de expertos con contexto arquitectonico
> - [PRD.md](PRD.md) — Product Requirements Document
> - [SUGGESTIONS.md](SUGGESTIONS.md) — Sugerencias y mejoras propuestas

---

## 1. Stack Tecnologico

### Ya configurado en el proyecto
| Tecnologia | Version | Uso |
|------------|---------|-----|
| Ruby | 3.3.6 | Runtime |
| Rails | 8.1.2 | Framework |
| PostgreSQL | 16+ | Base de datos principal |
| Tailwind CSS | 4 | Framework CSS (via tailwindcss-rails) |
| Hotwire | Turbo + Stimulus | Interactividad sin SPA |
| Propshaft | latest | Asset pipeline |
| Import Maps | latest | JavaScript modules |
| Solid Queue | latest | Background jobs (PostgreSQL-backed) |
| Solid Cache | latest | Cache (PostgreSQL-backed) |
| Solid Cable | latest | WebSockets (PostgreSQL-backed) |
| Puma | 6+ | Web server |
| RSpec | latest | Testing framework |
| FactoryBot | latest | Test fixtures |

### Por agregar
| Gem | Version | Uso |
|-----|---------|-----|
| `dry-types` | ~> 1.7 | Sistema de tipos estrictos |
| `dry-struct` | ~> 1.6 | Structs inmutables con tipos |
| `dry-validation` | ~> 1.10 | Contratos de validacion de input |
| `dry-monads` | ~> 1.6 | Result (Success/Failure), Maybe, Try |
| `bcrypt` | ~> 3.1 | Ya incluido (has_secure_password) |
| `pagy` | ~> 9.0 | Paginacion performante |
| `money-rails` | ~> 1.15 | Formateo de divisas y conversion FX |

> **Nota sobre filtros:** Filtros se implementan con ActiveRecord scopes. Ransack se agrega solo cuando filtros complejos lo requieran.
>
> **Nota sobre money-rails:** Reemplaza Value Object Money custom. Usado para formateo de divisas y conversion FX.

---

## 2. Arquitectura de la Aplicacion

### 2.1 Principios Arquitectonicos

**Hexagonal / Ports & Adapters:**
- **Driving Adapters (entrada):** Controllers, Background Jobs, Rake Tasks
- **Input Ports:** Use Cases (`app/contexts/{context}/use_cases/`) — orquestan la logica de negocio
- **Domain Core:** Entities (models), Domain Services (`app/contexts/{context}/domain/`), Domain Events (`app/contexts/{context}/events/`), Types
- **Output Ports:** Gateways (`app/contexts/market_data/gateways/`)
- **Driven Adapters (salida):** ActiveRecord, API Clients (Polygon, CoinGecko, Alpha Vantage, FMP, Yahoo Finance), ActionMailer, ActionCable

> **Nota sobre Repository pattern:** En v1 los Use Cases interactuan con ActiveRecord directamente (driven adapter). El patron Repository se introduce solo si se necesita cambiar de ORM.

**Domain-Driven Design:**
- 5 Bounded Contexts: Identity, Trading, Alerts, Market Intelligence, Administration
- Domain Events para comunicacion entre contextos
- Value Objects para conceptos inmutables (GainLoss, AlertCondition)

**Principios de implementacion:**
1. **Controllers delgados** — Solo parsean HTTP, llaman un Use Case y renderizan Turbo response
2. **Models delgados** — Solo asociaciones, scopes, enums y validaciones de BD (driven adapters)
3. **Logica en Use Cases** — Toda logica de negocio vive en `app/contexts/{context}/use_cases/` (input ports)
4. **Validacion en Contracts** — Toda validacion de input vive en `app/contexts/{context}/contracts/`
5. **Domain Events para side effects** — Eventos publicados al final de Use Cases, handlers asincronos
6. **Types centralizados** — Tipos reutilizables en `app/shared/types/`
7. **Railway-oriented** — Use Cases retornan `Success(value)` o `Failure([:type, error])` (dry-monads)
8. **Hotwire-first** — Toda interaccion usa Turbo Drive/Frames/Streams + Stimulus
9. **Dependencias hacia adentro** — Adapters dependen de Ports, nunca al reves

> Ver [COMMANDS.md](COMMANDS.md) para el catalogo completo de Use Cases, Events y Bounded Contexts.

### 2.2 Estructura de Carpetas (Hexagonal por Bounded Context)

```
app/
├── contexts/                          # BOUNDED CONTEXTS — Logica de negocio por dominio
│   ├── identity/                      # BC: Identity (auth, profiles, onboarding)
│   │   ├── contracts/                 # Identity::Contracts::*
│   │   ├── events/                    # Identity::Events::*
│   │   ├── handlers/                  # Identity::Handlers::*
│   │   └── use_cases/                 # Identity::UseCases::*
│   │
│   ├── trading/                       # BC: Trading (portfolio, trades, watchlist, dashboard)
│   │   ├── contracts/                 # Trading::Contracts::*
│   │   ├── domain/                    # Trading::Domain::* (PortfolioSummary, SplitAdjuster, etc.)
│   │   ├── events/                    # Trading::Events::*
│   │   ├── handlers/                  # Trading::Handlers::*
│   │   └── use_cases/                 # Trading::UseCases::*
│   │
│   ├── alerts/                        # BC: Alerts (rules, evaluation, triggering)
│   │   ├── contracts/                 # Alerts::Contracts::*
│   │   ├── domain/                    # Alerts::Domain::* (AlertEvaluator)
│   │   ├── events/                    # Alerts::Events::*
│   │   ├── handlers/                  # Alerts::Handlers::*
│   │   └── use_cases/                 # Alerts::UseCases::*
│   │
│   ├── market_data/                   # BC: Market Data (prices, gateways, fundamentals, news)
│   │   ├── domain/                    # MarketData::Domain::* (MarketSentiment, TrendScoreCalculator, etc.)
│   │   ├── events/                    # MarketData::Events::*
│   │   ├── gateways/                  # MarketData::Gateways::* (Polygon, CoinGecko, Alpha Vantage, etc.)
│   │   ├── handlers/                  # MarketData::Handlers::*
│   │   └── use_cases/                 # MarketData::UseCases::*
│   │
│   ├── administration/                # BC: Administration (admin ops, integrations, logs)
│   │   ├── contracts/                 # Administration::Contracts::*
│   │   ├── events/                    # Administration::Events::*
│   │   ├── handlers/                  # Administration::Handlers::*
│   │   └── use_cases/                 # Administration::UseCases::* (nested: Assets::, Users::, etc.)
│   │
│   └── notifications/                 # BC: Notifications (creation, delivery)
│       ├── events/                    # Notifications::Events::*
│       ├── handlers/                  # Notifications::Handlers::*
│       └── use_cases/                 # Notifications::UseCases::*
│
├── shared/                            # CROSS-CUTTING — Shared infrastructure (no namespace prefix)
│   ├── base/                          # ApplicationUseCase, ApplicationContract
│   ├── domain/                        # CircuitBreaker, RateLimiter, GatewayChain, etc.
│   ├── events/                        # BaseEvent, EventBus
│   └── types/                         # Types (Dry::Types)
│
├── controllers/                       # DRIVING ADAPTERS — HTTP
│   ├── application_controller.rb
│   ├── authenticated_controller.rb
│   ├── admin/
│   │   └── base_controller.rb
│   └── ...                            # Feature controllers
│
├── models/                            # DRIVEN ADAPTERS — ActiveRecord (PostgreSQL)
├── views/                             # Presentacion (ERB + Turbo)
├── javascript/controllers/            # Stimulus controllers
├── jobs/                              # DRIVING ADAPTERS — Background (Solid Queue)
└── assets/stylesheets/
    └── application.tailwind.css
```

> **Naming convention:** Organizational folders within each context map to Ruby modules.
> Example: `app/contexts/identity/events/user_registered.rb` → `Identity::Events::UserRegistered`
> Shared infrastructure folders are collapsed (no namespace): `app/shared/domain/circuit_breaker.rb` → `CircuitBreaker`

---

## 3. Patron Use Case (Input Port) con dry-rb

> Ver [COMMANDS.md](COMMANDS.md) para el catalogo completo de todos los Use Cases con codigo.

### 3.1 Base Use Case

```ruby
# app/shared/base/application_use_case.rb
class ApplicationUseCase
  include Dry::Monads[:result, :do]

  def self.call(...)
    new.call(...)
  end

  private

  def validate(contract_class, params)
    result = contract_class.new.call(params)
    result.success? ? Success(result.to_h) : Failure([:validation, result.errors.to_h])
  end

  def publish(event)
    EventBus.publish(event)
    Success(event)
  end
end
```

### 3.2 Base Contract

```ruby
# app/shared/base/application_contract.rb
class ApplicationContract < Dry::Validation::Contract
  config.messages.backend = :i18n
end
```

### 3.3 Types Module

```ruby
# app/shared/types/types.rb
module Types
  include Dry.Types()

  UserRole    = Types::String.enum("user", "admin")
  UserStatus  = Types::String.enum("active", "suspended")

  AssetType   = Types::String.enum("stock", "crypto", "index")
  SyncStatus  = Types::String.enum("active", "disabled", "sync_issue")

  AlertCondition = Types::String.enum(
    "price_crosses_above", "price_crosses_below",
    "day_change_percent", "rsi_overbought", "rsi_oversold"
  )
  AlertStatus = Types::String.enum("active", "paused")
  EventStatus = Types::String.enum("triggered", "settled")

  PositionStatus = Types::String.enum("open", "closed")

  EarningsTiming = Types::String.enum("before_market_open", "after_market_close")

  LogSeverity = Types::String.enum("success", "error", "warning")

  ConnectionStatus = Types::String.enum("connected", "syncing", "disconnected")

  Currency = Types::String.default("USD")
end
```

### 3.4 Ejemplo: Flujo Completo (Contract → Use Case → Event → Controller)

```ruby
# 1. Contract (validacion de input)
# app/contexts/alerts/contracts/create_contract.rb
module Alerts
  module Contracts
    class CreateContract < ApplicationContract
      params do
        required(:asset_symbol).filled(:string)
        required(:condition).filled(:string, included_in?: %w[
          price_crosses_above price_crosses_below
          day_change_percent rsi_overbought rsi_oversold
        ])
        required(:threshold_value).filled(:decimal)
      end

      rule(:asset_symbol) do
        key.failure("must be a valid ticker") unless /\A[A-Z0-9\/\.]{1,12}\z/.match?(value)
      end
    end
  end
end

# 2. Domain Event
# app/contexts/alerts/events/alert_rule_created.rb
module Alerts
  module Events
    class AlertRuleCreated < BaseEvent
      attribute :user_id, Types::Integer
      attribute :rule_id, Types::Integer
    end
  end
end

# 3. Use Case (input port — logica de negocio)
# app/contexts/alerts/use_cases/create_rule.rb
module Alerts
  module UseCases
    class CreateRule < ApplicationUseCase
      def call(user:, params:)
        attrs = yield validate(Alerts::Contracts::CreateContract, params)
        rule  = yield persist(user, attrs)
        _     = yield publish(Events::AlertRuleCreated.new(user_id: user.id, rule_id: rule.id))

        Success(rule)
      end

      private

      def persist(user, attrs)
        rule = user.alert_rules.build(attrs)
        rule.save ? Success(rule) : Failure([:persistence, rule.errors.full_messages])
      end
    end
  end
end

# 4. Controller (driving adapter — coordina HTTP ↔ Use Case ↔ Turbo)
# app/controllers/alerts_controller.rb
class AlertsController < AuthenticatedController
  def create
    case Alerts::UseCases::CreateRule.call(user: current_user, params: alert_params)
    in Success(alert)
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.prepend("alert_rules", partial: "alerts/alert_rule", locals: { alert: }),
            turbo_stream.replace("alert_form", partial: "alerts/form", locals: { alert: AlertRule.new }),
            turbo_stream.prepend("flash_messages", partial: "shared/flash", locals: { type: :notice, message: "Alert created" })
          ]
        }
        format.html { redirect_to alerts_path, notice: "Alert created" }
      end
    in Failure([:validation, errors])
      render turbo_stream: turbo_stream.replace("alert_form_errors",
        partial: "shared/form_errors", locals: { errors: })
    in Failure([:persistence, errors])
      redirect_to alerts_path, alert: errors.join(", ")
    end
  end

  private

  def alert_params
    params.require(:alert).permit(:asset_symbol, :condition, :threshold_value)
  end
end
```

---

## 4. Autenticacion (Rails 8 nativo)

### 4.1 Estrategia

Rails 8 incluye `has_secure_password` con mejoras. No usaremos Devise — autenticacion manual y simple.

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # Asociaciones, enums, scopes...
end
```

### 4.2 Controlador de Sesion

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  layout "public"

  def new; end

  def create
    case Identity::UseCases::Login.call(params: session_params)
    in Success(user)
      start_session(user)
      redirect_to dashboard_path, notice: "Welcome back, #{user.full_name}!"
    in Failure(error)
      flash.now[:alert] = error
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out successfully"
  end

  private

  def start_session(user)
    reset_session
    session[:user_id] = user.id
  end

  def session_params
    params.permit(:email, :password, :remember_me)
  end
end
```

### 4.3 Controlador Base Autenticado

```ruby
# app/controllers/authenticated_controller.rb
class AuthenticatedController < ApplicationController
  layout "app"
  before_action :require_authentication

  private

  def require_authentication
    redirect_to login_path, alert: "Please sign in" unless current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  helper_method :current_user
end
```

### 4.4 Admin Base

```ruby
# app/controllers/admin/base_controller.rb
module Admin
  class BaseController < AuthenticatedController
    layout "admin"
    before_action :require_admin

    private

    def require_admin
      redirect_to dashboard_path, alert: "Not authorized" unless current_user&.admin?
    end
  end
end
```

---

## 5. Hotwire — Estrategia de Interactividad

### 5.1 Turbo Drive (navegacion global)
- **Activo por defecto** — Toda navegacion entre paginas es SPA-like
- Links y formularios se interceptan automaticamente
- Sin configuracion adicional necesaria
- Flash messages se muestran via Turbo morphing

### 5.2 Turbo Frames (actualizaciones parciales)

| Componente | Frame ID | Trigger | Accion |
|------------|----------|---------|--------|
| Market Listings table | `market_listings` | Filtros, paginacion | Reemplaza tabla |
| Portfolio positions tabs | `positions_tab` | Click en tab | Cambia contenido |
| Earnings calendar grid | `calendar_grid` | Navegacion mes | Reemplaza calendario |
| Admin asset table | `admin_assets_table` | Tabs All/Stocks/Crypto | Filtra tabla |
| Admin logs table | `admin_logs_table` | Filtros | Actualiza tabla |
| Admin users table | `admin_users_table` | Busqueda | Actualiza tabla |
| Currency-dependent KPIs | `kpi_cards` | Selector divisa | Recalcula valores |
| Dashboard news feed | `news_feed` | Load more | Append noticias |
| News feed page | `news_listings` | Filtros, infinite scroll | Reemplaza/append noticias |
| Global search results | `search_results` | Input con debounce | Reemplaza resultados |
| Notification dropdown | `notification_list` | Click campana | Carga lista |
| Onboarding step content | `onboarding_step` | Click siguiente/atras | Cambia paso |

**Ejemplo en vista:**
```erb
<%# app/views/market/index.html.erb %>
<%= turbo_frame_tag "market_listings" do %>
  <%= render "market/listings_table", assets: @assets %>
  <%= render "shared/pagination", pagy: @pagy %>
<% end %>
```

### 5.3 Turbo Streams (mutaciones en vivo)

| Accion | Stream Action | Target |
|--------|--------------|--------|
| Crear alerta | `prepend` | `#alert_rules` |
| Eliminar alerta | `remove` | `#alert_rule_{id}` |
| Toggle alerta (pause/active) | `replace` | `#alert_rule_{id}` |
| Agregar a watchlist | `append` | `#watchlist_items` |
| Remover de watchlist | `remove` | `#watchlist_item_{id}` |
| Update perfil | `replace` | `#profile_header` |
| Toggle delivery preference | `replace` | `#delivery_pref_{type}` |
| Admin: toggle asset status | `replace` | `#asset_row_{id}` |
| Admin: suspend user | `replace` | `#user_row_{id}` |
| Flash message | `prepend` | `#flash_messages` |
| Nueva notificacion (broadcast) | `prepend` | `#notification_list` |
| Badge notificaciones (broadcast) | `replace` | `#notification_badge` |
| Marcar notificacion leida | `replace` | `#notification_{id}` |

**Ejemplo en controller:**
```erb
<%# alerts/create.turbo_stream.erb %>
<%= turbo_stream.prepend "alert_rules" do %>
  <%= render "alerts/alert_rule", alert: @alert %>
<% end %>

<%= turbo_stream.replace "alert_form" do %>
  <%= render "alerts/form", alert: AlertRule.new %>
<% end %>

<%= turbo_stream.prepend "flash_messages" do %>
  <%= render "shared/flash", type: :notice, message: "Alert created successfully" %>
<% end %>
```

### 5.4 Stimulus Controllers

| Controller | Responsabilidad | Usado en |
|------------|----------------|----------|
| `flash` | Auto-dismiss flash messages despues de 5s | Global |
| `dropdown` | Toggle menu desplegable (notificaciones, perfil) | App navbar |
| `tabs` | Cambio de tabs sin server (cuando es visual) | Portfolio, Admin |
| `modal` | Abrir/cerrar modals (Add Asset, Buy/Sell) | Portfolio, Admin |
| `toggle` | Toggle switches con submit automatico | Profile settings, Admin |
| `search` | Debounce 300ms + submit form | Market, Admin |
| `slider` | Range slider con valor visible | Market (Trend Strength) |
| `scroll_to` | Scroll suave a seccion (TOC) | Legal pages |
| `back_to_top` | Mostrar/ocultar boton scroll top | Legal pages |
| `clipboard` | Copiar texto (API keys, git commands) | Admin, Open Source |
| `auto_refresh` | Polling periodico (30s) via Turbo Frame | Admin Logs |
| `currency_selector` | Submit form al cambiar divisa | Dashboard, Portfolio |
| `calendar` | Navegacion mes anterior/siguiente | Earnings |
| `chart` | Hover tooltip en SVG chart | Trend Explorer |
| `confirm` | Confirmacion antes de accion destructiva | Alerts delete, Admin suspend |
| `notification` | Dropdown de notificaciones + badge count | App navbar |
| `onboarding` | Wizard step navigation, progress bar, skip/continue | Onboarding |
| `global_search` | Cmd+K shortcut, debounce input, keyboard nav (arrows/enter/esc), grouped results | App navbar |
| `infinite_scroll` | Observa sentinel element, carga pagina siguiente via Turbo Frame | News Feed |

**Ejemplo Stimulus:**
```javascript
// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.dismiss(), 5000)
  }

  dismiss() {
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")
    setTimeout(() => this.element.remove(), 300)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
```

---

## 6. Layouts — Implementacion Tecnica

### 6.1 Herencia de Layouts

```
application.html.erb (base: meta, Tailwind, JS, Material Symbols, Inter font)
├── public.html.erb    → content_for(:layout) { render "application" }
├── app.html.erb       → content_for(:layout) { render "application" }
├── admin.html.erb     → content_for(:layout) { render "application" }
└── legal.html.erb     → content_for(:layout) { render "application" }
```

> **Nota:** Auth pages (login, registro) usan el layout `public` con una variante CSS. No existe un layout `auth` separado.

### 6.2 Seleccion de Layout por Controller

```ruby
# Cada controller base define su layout:
class PagesController < ApplicationController
  layout "public"
end

class SessionsController < ApplicationController
  layout "public"
end

class AuthenticatedController < ApplicationController
  layout "app"
end

class Admin::BaseController < AuthenticatedController
  layout "admin"
end

class LegalController < ApplicationController
  layout "legal"
end
```

---

## 7. Paginacion

Usar **Pagy** (la gem mas rapida para Rails):

```ruby
# app/controllers/market_controller.rb
class MarketController < AuthenticatedController
  include Pagy::Backend

  def index
    case MarketData::UseCases::ExploreAssets.call(params: filter_params)
    in Success(result)
      @pagy, @assets = pagy(result[:assets], items: 10)
      @indices = result[:indices]
    in Failure([:validation, errors])
      @assets = Asset.none
      flash.now[:alert] = errors
    end
  end
end
```

Pagy se integra naturalmente con Turbo Frames para paginacion sin recarga.

---

## 8. Busqueda y Filtros

Usar **ActiveRecord scopes** con `ILIKE` para busqueda de texto dentro de Use Cases para filtros del Market Explorer y Admin:

```ruby
# Los filtros se implementan con ActiveRecord scopes directamente.
# Ejemplo de scope para busqueda de texto:
#   scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") if query.present? }
#
# El Use Case Market::ExploreAssets construye el scope con filtros y retorna Success(assets_scope)
# El controller solo pagina el resultado con Pagy
```

---

## 9. Background Jobs (Solid Queue)

Jobs que se ejecutaran via Solid Queue (ya configurado):

| Job | Trigger | Descripcion |
|-----|---------|-------------|
| `SyncAssetsJob` | Cron / Manual | Sincronizar precios de activos desde APIs |
| `CheckAlertsJob` | Cron (cada 5min) | Evaluar reglas de alerta contra precios actuales |
| `CleanupLogsJob` | Cron (diario) | Eliminar logs de sistema > 90 dias |
| `RefreshFxRatesJob` | Cron (cada 1h) | Actualizar tasas de cambio |
| `SnapshotPortfoliosJob` | Cron (diario) | Tomar snapshot de portfolios para historico |
| `GenerateAlertEventJob` | Async | Crear evento de alerta + notificar |

---

## 10. Testing Strategy

```
spec/
├── contexts/             # Mirrors app/contexts/ — organized by bounded context
│   ├── identity/         # contracts/, events/, handlers/, use_cases/
│   ├── trading/          # contracts/, domain/, events/, handlers/, use_cases/
│   ├── alerts/           # contracts/, domain/, events/, handlers/, use_cases/
│   ├── market_data/      # domain/, events/, gateways/, handlers/, use_cases/
│   ├── administration/   # contracts/, events/, handlers/, use_cases/
│   └── notifications/    # handlers/, use_cases/
├── shared/               # Mirrors app/shared/ — base classes, domain, events
├── models/               # Validations, enums, associations, scopes
├── requests/             # HTTP smoke tests, guards, CRUD flows
├── jobs/                 # Background job behavior
├── system/               # Capybara end-to-end browser tests
├── integration/          # Multi-layer flow tests + event subscription wiring
└── factories/            # FactoryBot definitions
```

**Prioridad de testing:**
1. Use Cases (unit) — Toda logica de negocio, verificar Success/Failure
2. Contracts (unit) — Toda validacion de input
3. Domain (unit) — Value Objects y Domain Services
4. Requests (integration) — Flujos HTTP criticos (auth, CRUD, Turbo Streams)
5. System (e2e) — Flujos de usuario principales con Turbo

---

## 11. Configuracion de Tailwind

```css
/* app/assets/stylesheets/application.tailwind.css */
@import "tailwindcss";

@theme {
  --color-primary-50: #e6f0ff;
  --color-primary-100: #b3d1ff;
  --color-primary-200: #80b3ff;
  --color-primary-300: #4d94ff;
  --color-primary-400: #1a75ff;
  --color-primary-500: #004a99;
  --color-primary-600: #003d80;
  --color-primary-700: #003066;
  --color-primary-800: #00234d;
  --color-primary-900: #001633;
}
```

---

## 12. Gems Adicionales a Agregar

```ruby
# Gemfile (agregar a las ya existentes)

# --- dry-rb ecosystem ---
gem "dry-types",       "~> 1.7"
gem "dry-struct",      "~> 1.6"
gem "dry-validation",  "~> 1.10"
gem "dry-monads",      "~> 1.6"

# --- Utilidades ---
gem "pagy",        "~> 9.0"     # Paginacion
gem "money-rails", "~> 1.15"    # Formateo de divisas y conversion FX
```
