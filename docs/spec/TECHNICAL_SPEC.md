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
- **Input Ports:** Use Cases (`app/use_cases/`) — orquestan la logica de negocio
- **Domain Core:** Entities (models), Value Objects (`app/domain/`), Domain Events (`app/events/`), Types
- **Output Ports:** Gateways (`app/gateways/`), Notifiers (`app/notifiers/`)
- **Driven Adapters (salida):** ActiveRecord, API Clients (Polygon, CoinGecko), ActionMailer, ActionCable

> **Nota sobre Repository pattern:** En v1 los Use Cases interactuan con ActiveRecord directamente (driven adapter). El patron Repository se introduce solo si se necesita cambiar de ORM.

**Domain-Driven Design:**
- 5 Bounded Contexts: Identity, Trading, Alerts, Market Intelligence, Administration
- Domain Events para comunicacion entre contextos
- Value Objects para conceptos inmutables (GainLoss, AlertCondition)

**Principios de implementacion:**
1. **Controllers delgados** — Solo parsean HTTP, llaman un Use Case y renderizan Turbo response
2. **Models delgados** — Solo asociaciones, scopes, enums y validaciones de BD (driven adapters)
3. **Logica en Use Cases** — Toda logica de negocio vive en `app/use_cases/` (input ports)
4. **Validacion en Contracts** — Toda validacion de input vive en `app/contracts/`
5. **Domain Events para side effects** — Eventos publicados al final de Use Cases, handlers asincronos
6. **Types centralizados** — Tipos reutilizables en `app/types/`
7. **Railway-oriented** — Use Cases retornan `Success(value)` o `Failure([:type, error])` (dry-monads)
8. **Hotwire-first** — Toda interaccion usa Turbo Drive/Frames/Streams + Stimulus
9. **Dependencias hacia adentro** — Adapters dependen de Ports, nunca al reves

> Ver [COMMANDS.md](COMMANDS.md) para el catalogo completo de Use Cases, Events y Bounded Contexts.

### 2.2 Estructura de Carpetas (Hexagonal)

```
app/
├── use_cases/                      # INPUT PORTS — Logica de negocio
│   ├── application_use_case.rb     # Base: dry-monads, validate helper, publish helper
│   ├── sessions/                   # Bounded Context: Identity
│   │   ├── authenticate.rb
│   │   └── logout.rb
│   ├── registrations/
│   │   └── register_user.rb
│   ├── dashboard/                  # Bounded Context: Trading
│   │   └── assemble.rb
│   ├── portfolio/
│   │   └── load_overview.rb
│   ├── positions/
│   │   ├── open_position.rb
│   │   └── close_position.rb
│   ├── watchlist/                  # Bounded Context: Trading (Watchlist)
│   │   ├── add_asset.rb
│   │   └── remove_asset.rb
│   ├── alerts/                     # Bounded Context: Alerts
│   │   ├── create_rule.rb
│   │   ├── update_rule.rb
│   │   ├── toggle_rule.rb
│   │   ├── destroy_rule.rb
│   │   └── update_preferences.rb
│   ├── market/                     # Bounded Context: Market Intelligence
│   │   ├── explore_assets.rb
│   │   └── export_csv.rb
│   ├── earnings/
│   │   └── list_for_month.rb
│   ├── trends/
│   │   └── load_asset_trend.rb
│   ├── profiles/
│   │   ├── update_info.rb
│   │   └── change_password.rb
│   └── admin/                      # Bounded Context: Administration
│       ├── assets/
│       │   ├── create_asset.rb
│       │   ├── toggle_status.rb
│       │   └── trigger_sync.rb
│       ├── users/
│       │   ├── update_user.rb
│       │   └── suspend_user.rb
│       ├── integrations/
│       │   ├── connect_provider.rb
│       │   ├── refresh_sync.rb
│       │   └── disconnect_provider.rb
│       └── logs/
│           ├── list_logs.rb
│           └── export_csv.rb
│
├── contracts/                      # INPUT VALIDATION — dry-validation
│   ├── application_contract.rb
│   ├── sessions/
│   ├── registrations/
│   ├── alerts/
│   ├── positions/
│   ├── profiles/
│   ├── market/
│   └── admin/
│
├── domain/                         # DOMAIN CORE — Value Objects y Services
│   ├── gain_loss.rb                # Value Object: absolute + percent
│   ├── alert_condition.rb          # Value Object: condition + threshold
│   ├── trend_direction.rb          # Value Object: upward/downward
│   ├── portfolio_summary.rb        # Domain Service: calcula KPIs
│   └── fx_converter.rb             # Domain Service: conversion de divisas
│
├── events/                         # DOMAIN EVENTS
│   ├── base_event.rb               # Base con dry-struct + occurred_at
│   ├── event_bus.rb                # Publicador/suscriptor sincronico
│   ├── user_registered.rb
│   ├── password_changed.rb
│   ├── profile_updated.rb
│   ├── alert_rule_created.rb
│   ├── alert_rule_triggered.rb
│   ├── position_opened.rb
│   ├── position_closed.rb
│   ├── trade_executed.rb
│   ├── watchlist_item_added.rb
│   ├── asset_synced.rb
│   ├── asset_price_updated.rb
│   ├── portfolio_snapshot_taken.rb
│   ├── notification_created.rb
│   ├── fx_rates_refreshed.rb
│   ├── csv_exported.rb
│   ├── user_suspended.rb
│   └── integration_connected.rb
│
├── event_handlers/                 # SIDE EFFECTS — Reaccionan a Domain Events (flat naming)
│   ├── create_portfolio_on_registration.rb
│   ├── create_alert_preferences_on_registration.rb
│   ├── send_welcome_email_on_registration.rb
│   ├── create_alert_event_on_trigger.rb
│   ├── create_notification_on_alert.rb
│   ├── broadcast_notification.rb
│   ├── evaluate_alerts_on_price_update.rb
│   ├── broadcast_price_update.rb
│   ├── recalculate_avg_cost_on_trade.rb
│   ├── log_trade_activity.rb
│   ├── invalidate_sessions_on_password_change.rb
│   ├── send_suspension_email.rb
│   ├── create_audit_log.rb
│   └── log_integration_connected.rb
│
├── gateways/                       # OUTPUT PORTS — APIs externas
│   ├── market_data_gateway.rb      # Interface base
│   ├── polygon_gateway.rb          # Adapter: Polygon.io
│   ├── coingecko_gateway.rb        # Adapter: CoinGecko
│   └── fx_rates_gateway.rb         # Adapter: tasas de cambio
│
├── notifiers/                      # OUTPUT PORTS — Notificaciones
│   ├── alert_notifier.rb           # Interface base
│   ├── email_notifier.rb           # Adapter: ActionMailer
│   ├── browser_push_notifier.rb    # Adapter: Web Push
│   └── turbo_stream_notifier.rb    # Adapter: Turbo broadcast
│
├── types/                          # DOMAIN CORE — dry-types
│   └── types.rb
│
├── controllers/                    # DRIVING ADAPTERS — HTTP
│   ├── application_controller.rb
│   ├── authenticated_controller.rb
│   ├── admin/
│   │   ├── base_controller.rb
│   │   ├── assets_controller.rb
│   │   ├── logs_controller.rb
│   │   └── users_controller.rb
│   ├── pages_controller.rb
│   ├── legal_controller.rb
│   ├── trends_controller.rb
│   ├── sessions_controller.rb
│   ├── registrations_controller.rb
│   ├── password_resets_controller.rb
│   ├── dashboard_controller.rb
│   ├── market_controller.rb
│   ├── portfolio_controller.rb
│   ├── alerts_controller.rb
│   ├── earnings_controller.rb
│   ├── notifications_controller.rb
│   ├── watchlist_controller.rb
│   ├── profile_controller.rb
│   ├── news_controller.rb
│   ├── onboarding_controller.rb
│   └── search_controller.rb
│
├── models/                         # DRIVEN ADAPTERS — ActiveRecord (PostgreSQL)
│   ├── application_record.rb
│   ├── user.rb
│   ├── asset.rb                   # Incluye price_updated_at para tracking de frescura
│   ├── portfolio.rb
│   ├── position.rb
│   ├── trade.rb
│   ├── portfolio_snapshot.rb
│   ├── watchlist_item.rb
│   ├── alert_rule.rb
│   ├── alert_event.rb
│   ├── alert_preference.rb
│   ├── earnings_event.rb
│   ├── news_article.rb
│   ├── market_index.rb
│   ├── trend_score.rb
│   ├── fx_rate.rb
│   ├── asset_price_history.rb
│   ├── notification.rb
│   ├── audit_log.rb
│   ├── dividend.rb
│   ├── dividend_payment.rb
│   ├── remember_token.rb
│   ├── system_log.rb
│   └── integration.rb
│
├── views/
│   ├── layouts/
│   │   ├── application.html.erb
│   │   ├── public.html.erb
│   │   ├── app.html.erb
│   │   ├── admin.html.erb
│   │   └── legal.html.erb
│   ├── shared/
│   ├── components/
│   ├── pages/
│   ├── legal/
│   ├── trends/
│   ├── sessions/
│   ├── registrations/
│   ├── dashboard/
│   ├── market/
│   ├── portfolio/
│   ├── alerts/
│   ├── earnings/
│   ├── profile/
│   ├── news/
│   ├── onboarding/
│   ├── search/
│   ├── notifications/
│   └── admin/
│
├── javascript/controllers/         # Stimulus controllers
│   ├── flash_controller.js
│   ├── dropdown_controller.js
│   ├── tabs_controller.js
│   ├── modal_controller.js
│   ├── toggle_controller.js
│   ├── search_controller.js
│   ├── slider_controller.js
│   ├── scroll_to_controller.js
│   ├── back_to_top_controller.js
│   ├── clipboard_controller.js
│   ├── auto_refresh_controller.js
│   ├── currency_selector_controller.js
│   ├── calendar_controller.js
│   ├── chart_controller.js
│   ├── notification_controller.js  # Dropdown + badge count de notificaciones
│   ├── onboarding_controller.js   # Wizard step navigation
│   ├── global_search_controller.js # Cmd+K shortcut, debounce, keyboard nav
│   └── infinite_scroll_controller.js # Scroll-to-load-more para news feed
│
├── jobs/                           # DRIVING ADAPTERS — Background
│   ├── sync_assets_job.rb
│   ├── check_alerts_job.rb
│   ├── cleanup_logs_job.rb
│   ├── refresh_fx_rates_job.rb
│   ├── snapshot_portfolios_job.rb
│   └── sync_integration_job.rb
│
└── assets/stylesheets/
    └── application.tailwind.css
```

---

## 3. Patron Use Case (Input Port) con dry-rb

> Ver [COMMANDS.md](COMMANDS.md) para el catalogo completo de todos los Use Cases con codigo.

### 3.1 Base Use Case

```ruby
# app/use_cases/application_use_case.rb
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
# app/contracts/application_contract.rb
class ApplicationContract < Dry::Validation::Contract
  config.messages.backend = :i18n
end
```

### 3.3 Types Module

```ruby
# app/types/types.rb
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
# app/contracts/alerts/create_contract.rb
module Alerts
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

# 2. Domain Event
# app/events/alert_rule_created.rb
class AlertRuleCreated < BaseEvent
  attribute :user_id, Types::Integer
  attribute :rule_id, Types::Integer
end

# 3. Use Case (input port — logica de negocio)
# app/use_cases/alerts/create_rule.rb
module Alerts
  class CreateRule < ApplicationUseCase
    def call(user:, params:)
      attrs = yield validate(Alerts::CreateContract, params)
      rule  = yield persist(user, attrs)
      _     = yield publish(AlertRuleCreated.new(user_id: user.id, rule_id: rule.id))

      Success(rule)
    end

    private

    def persist(user, attrs)
      rule = user.alert_rules.build(attrs)
      rule.save ? Success(rule) : Failure([:persistence, rule.errors.full_messages])
    end
  end
end

# 4. Controller (driving adapter — coordina HTTP ↔ Use Case ↔ Turbo)
# app/controllers/alerts_controller.rb
class AlertsController < AuthenticatedController
  def create
    case Alerts::CreateRule.call(user: current_user, params: alert_params)
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
    case Sessions::Authenticate.call(params: session_params)
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
    case Market::ExploreAssets.call(params: filter_params)
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
├── use_cases/           # Unit tests para cada Use Case (input ports)
│   ├── sessions/
│   ├── registrations/
│   ├── dashboard/
│   ├── market/
│   ├── portfolio/
│   ├── positions/
│   ├── watchlist/
│   ├── alerts/
│   ├── earnings/
│   ├── trends/
│   ├── profiles/
│   └── admin/
├── contracts/           # Tests de validacion (contratos de input)
├── domain/              # Tests de Value Objects y Domain Services
├── events/              # Tests de Domain Events y Event Handlers
├── gateways/            # Tests de Gateways (mocked API responses)
├── models/              # Tests de asociaciones, scopes, enums
├── requests/            # Integration tests (HTTP + Turbo response)
├── system/              # E2E tests con Capybara (flujos Turbo)
└── factories/           # FactoryBot definitions
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
