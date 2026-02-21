# Stockerly - Use Cases, Actions & Domain Architecture

> Arquitectura DDD con Ports & Adapters (Hexagonal), Event-Driven y dry-rb.
> Cada Use Case encapsula una accion de negocio completa, reutilizable y testeable de forma aislada.
>
> **Bounded Contexts:** 5 — Identity, Trading, Alerts, Market Data, Administration

---

## 1. Arquitectura General

### 1.1 Hexagonal (Ports & Adapters)

```
                        ┌─────────────────────────────────┐
                        │        DRIVING ADAPTERS          │
                        │  (entrada al sistema)            │
                        │                                  │
                        │  Controllers (HTTP/Turbo)        │
                        │  Background Jobs (Solid Queue)   │
                        │  Console / Rake Tasks            │
                        └──────────────┬──────────────────┘
                                       │ llaman
                        ┌──────────────▼──────────────────┐
                        │         INPUT PORTS              │
                        │  (interfaces de entrada)         │
                        │                                  │
                        │  Use Cases (app/use_cases/)      │
                        │  Contracts (app/contracts/)      │
                        └──────────────┬──────────────────┘
                                       │ orquestan
                        ┌──────────────▼──────────────────┐
                        │          DOMAIN CORE             │
                        │  (logica de negocio pura)        │
                        │                                  │
                        │  Entities     (app/models/)      │
                        │  Value Objects (app/domain/)     │
                        │  Domain Events (app/events/)     │
                        │  Domain Services                 │
                        │  Types (app/types/)              │
                        └──────────────┬──────────────────┘
                                       │ dependen de
                        ┌──────────────▼──────────────────┐
                        │         OUTPUT PORTS             │
                        │  (interfaces de salida)          │
                        │                                  │
                        │  Gateways (app/gateways/)        │
                        │  Notifiers (app/notifiers/)      │
                        └──────────────┬──────────────────┘
                                       │ implementados por
                        ┌──────────────▼──────────────────┐
                        │       DRIVEN ADAPTERS            │
                        │  (salida del sistema)            │
                        │                                  │
                        │  ActiveRecord (PostgreSQL)       │
                        │  Polygon.io API Client           │
                        │  CoinGecko API Client            │
                        │  ActionMailer (email)            │
                        │  ActionCable (websockets)        │
                        │  External HTTP (Faraday)         │
                        └─────────────────────────────────┘
```

> **Nota:** No usamos carpeta `repositories/` en v1. ActiveRecord funciona directamente como driven adapter para persistencia. Los Use Cases interactuan con los modelos directamente. Se introduce el patron Repository solo si se necesita cambiar de ORM o para queries muy complejas.

### 1.2 Flujo de una Request

```
HTTP Request
  → Controller (driving adapter)
    → Use Case (input port)
      → Contract (valida input)
      → Domain Logic (entities, value objects, domain services)
      → ActiveRecord (driven adapter directo)
      → Domain Event (publicado)
        → Event Handler(s) (sync o async via Solid Queue)
      → Result (Success / Failure)
    ← Controller renderiza Turbo Stream/Frame/HTML
```

---

## 2. Estructura de Carpetas

```
app/
├── contracts/                      # dry-validation: validacion de input
│   ├── application_contract.rb
│   ├── sessions/
│   ├── registrations/
│   ├── password_resets/
│   ├── alerts/
│   ├── positions/
│   ├── trades/
│   ├── profiles/
│   ├── watchlist/
│   ├── market/
│   ├── earnings/
│   ├── news/
│   ├── search/
│   ├── onboarding/
│   └── admin/
│
├── use_cases/                      # Acciones de negocio (input ports)
│   ├── application_use_case.rb     # Base class con dry-monads
│   ├── sessions/
│   │   ├── authenticate.rb
│   │   └── logout.rb
│   ├── registrations/
│   │   └── register_user.rb
│   ├── password_resets/
│   │   ├── request_reset.rb
│   │   └── execute_reset.rb
│   ├── dashboard/
│   │   └── assemble.rb
│   ├── market/
│   │   ├── explore_assets.rb
│   │   └── export_csv.rb
│   ├── portfolio/
│   │   └── load_overview.rb
│   ├── positions/
│   │   ├── open_position.rb
│   │   └── close_position.rb
│   ├── trades/
│   │   └── execute_trade.rb
│   ├── watchlist/                  # Parte del BC Trading (no BC separado)
│   │   ├── add_asset.rb
│   │   └── remove_asset.rb
│   ├── alerts/
│   │   ├── create_rule.rb
│   │   ├── update_rule.rb
│   │   ├── toggle_rule.rb
│   │   ├── destroy_rule.rb
│   │   ├── update_preferences.rb
│   │   └── evaluate_rules.rb
│   ├── notifications/
│   │   ├── create_notification.rb
│   │   └── mark_as_read.rb
│   ├── news/
│   │   └── list_articles.rb
│   ├── search/
│   │   └── global_search.rb
│   ├── onboarding/
│   │   └── complete_wizard.rb
│   ├── earnings/
│   │   └── list_for_month.rb
│   ├── trends/
│   │   └── load_asset_trend.rb
│   ├── profiles/
│   │   ├── update_info.rb
│   │   └── change_password.rb
│   ├── snapshots/
│   │   └── take_portfolio_snapshot.rb
│   └── admin/
│       ├── assets/
│       │   ├── create_asset.rb
│       │   ├── update_asset.rb
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
├── domain/                         # Value Objects y Domain Services
│   ├── gain_loss.rb                # Value Object: absolute + percent
│   ├── alert_condition.rb          # Value Object: condition + threshold
│   ├── trend_direction.rb          # Value Object: upward/downward
│   ├── portfolio_summary.rb        # Domain Service: calcula KPIs
│   ├── alert_evaluator.rb          # Domain Service: evalua condiciones de alertas
│   └── market_sentiment.rb         # Domain Service: calcula sentimiento desde trend scores
│
├── events/                         # Domain Events
│   ├── base_event.rb
│   ├── event_bus.rb
│   ├── user_registered.rb
│   ├── password_changed.rb
│   ├── profile_updated.rb
│   ├── alert_rule_created.rb
│   ├── alert_rule_triggered.rb
│   ├── position_opened.rb
│   ├── position_closed.rb
│   ├── trade_executed.rb
│   ├── watchlist_item_added.rb
│   ├── asset_price_updated.rb
│   ├── portfolio_snapshot_taken.rb
│   ├── notification_created.rb
│   ├── fx_rates_refreshed.rb
│   ├── csv_exported.rb
│   ├── user_suspended.rb
│   └── integration_connected.rb
│
├── event_handlers/                 # Reaccionan a Domain Events (side effects)
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
├── gateways/                       # Output Ports para servicios externos
│   ├── market_data_gateway.rb      # Interface
│   ├── polygon_gateway.rb          # Adapter: Polygon.io
│   ├── coingecko_gateway.rb        # Adapter: CoinGecko
│   └── fx_rates_gateway.rb         # Adapter: tasas de cambio
│
├── notifiers/                      # Output Ports para notificaciones
│   ├── alert_notifier.rb           # Interface base
│   ├── email_notifier.rb           # Adapter: ActionMailer
│   ├── browser_push_notifier.rb    # Adapter: Web Push
│   └── turbo_stream_notifier.rb    # Adapter: Turbo Stream broadcast
│
├── types/
│   └── types.rb                    # dry-types compartidos
│
├── models/                         # ActiveRecord Entities (driven adapter)
├── controllers/                    # Driving Adapters (HTTP)
├── views/                          # Presentacion
└── javascript/controllers/         # Stimulus
```

---

## 3. Base Classes

### 3.1 Application Use Case

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

### 3.2 Application Contract

```ruby
# app/contracts/application_contract.rb
class ApplicationContract < Dry::Validation::Contract
  config.messages.backend = :i18n
end
```

### 3.3 Base Event

```ruby
# app/events/base_event.rb
class BaseEvent
  include Dry::Struct

  attribute :occurred_at, Types::DateTime.default { DateTime.current }

  def event_name
    self.class.name.underscore.tr("/", ".")
  end
end
```

### 3.4 Event Bus (con soporte async)

```ruby
# app/events/event_bus.rb
class EventBus
  @handlers = Hash.new { |h, k| h[k] = [] }

  class << self
    def subscribe(event_class, handler)
      @handlers[event_class.name] << handler
    end

    def publish(event)
      @handlers[event.class.name].each do |handler|
        if handler.respond_to?(:async?) && handler.async?
          ProcessEventJob.perform_later(handler.name, event.to_h)
        else
          handler.call(event)
        end
      end
    end

    def clear!
      @handlers.clear
    end
  end
end
```

### 3.5 Types Module

```ruby
# app/types/types.rb
module Types
  include Dry.Types()

  UserRole    = Types::String.enum("user", "admin")
  UserStatus  = Types::String.enum("active", "suspended")

  AssetType   = Types::String.enum("stock", "crypto", "index")
  SyncStatus  = Types::String.enum("active", "disabled", "sync_issue")

  TradeSide   = Types::String.enum("buy", "sell")

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

  NotificationType = Types::String.enum("alert_triggered", "earnings_reminder", "system")

  Currency = Types::String.default("USD")
end
```

---

## 4. Catalogo Completo de Use Cases

### 4.1 Bounded Context: Identity (Autenticacion y Usuarios)

#### `Sessions::Authenticate`
```ruby
# app/use_cases/sessions/authenticate.rb
module Sessions
  class Authenticate < ApplicationUseCase
    def call(params:)
      attrs = yield validate(Sessions::AuthenticateContract, params)
      user  = yield find_user(attrs[:email])
      _     = yield verify_password(user, attrs[:password])
      _     = yield check_not_suspended(user)

      Success(user)
    end

    private

    def find_user(email)
      user = User.find_by(email: email.downcase)
      user ? Success(user) : Failure([:not_found, "Invalid email or password"])
    end

    def verify_password(user, password)
      user.authenticate(password) ? Success(true) : Failure([:unauthorized, "Invalid email or password"])
    end

    def check_not_suspended(user)
      user.suspended? ? Failure([:forbidden, "Account suspended"]) : Success(true)
    end
  end
end
```

**Contract:**
```ruby
# app/contracts/sessions/authenticate_contract.rb
module Sessions
  class AuthenticateContract < ApplicationContract
    params do
      required(:email).filled(:string)
      required(:password).filled(:string)
    end
  end
end
```

---

#### `Registrations::RegisterUser`
```ruby
# app/use_cases/registrations/register_user.rb
module Registrations
  class RegisterUser < ApplicationUseCase
    def call(params:)
      attrs = yield validate(Registrations::CreateContract, params)
      user  = yield persist(attrs)
      _     = yield publish(UserRegistered.new(user_id: user.id, email: user.email))

      Success(user)
    end

    private

    def persist(attrs)
      user = User.new(attrs.merge(role: :user))
      user.save ? Success(user) : Failure([:persistence, user.errors.full_messages])
    end
  end
end
```

**Contract:**
```ruby
# app/contracts/registrations/create_contract.rb
module Registrations
  class CreateContract < ApplicationContract
    params do
      required(:full_name).filled(:string, min_size?: 2)
      required(:email).filled(:string, format?: URI::MailTo::EMAIL_REGEXP)
      required(:password).filled(:string, min_size?: 8)
      required(:password_confirmation).filled(:string)
    end

    rule(:password_confirmation) do
      key.failure("must match password") if values[:password] != values[:password_confirmation]
    end

    rule(:email) do
      key.failure("already taken") if User.exists?(email: values[:email].downcase)
    end
  end
end
```

**Event:**
```ruby
# app/events/user_registered.rb
class UserRegistered < BaseEvent
  attribute :user_id, Types::Integer
  attribute :email,   Types::String
end
```

**Event Handlers:**
```ruby
# app/event_handlers/create_portfolio_on_registration.rb
class CreatePortfolioOnRegistration
  def self.call(event)
    user = User.find(event.user_id)
    user.create_portfolio!(inception_date: Date.current)
  end
end

# app/event_handlers/create_alert_preferences_on_registration.rb
class CreateAlertPreferencesOnRegistration
  def self.call(event)
    user = User.find(event.user_id)
    user.create_alert_preference!
  end
end

# app/event_handlers/send_welcome_email_on_registration.rb
class SendWelcomeEmailOnRegistration
  def self.async? = true

  def self.call(event)
    UserMailer.welcome(event.user_id).deliver_later
  end
end
```

---

#### `PasswordResets::RequestReset`
```ruby
# app/use_cases/password_resets/request_reset.rb
module PasswordResets
  class RequestReset < ApplicationUseCase
    def call(params:)
      attrs = yield validate(PasswordResets::RequestContract, params)
      user  = yield find_user(attrs[:email])
      token = yield generate_token(user)

      UserMailer.password_reset(user.id, token).deliver_later
      Success(:email_sent)
    end

    private

    def find_user(email)
      user = User.find_by(email: email.downcase)
      # Siempre retornar Success para no revelar si el email existe
      user ? Success(user) : Success(nil)
    end

    def generate_token(user)
      return Success(nil) unless user

      token = SecureRandom.urlsafe_base64(32)
      user.update!(
        password_reset_token: Digest::SHA256.hexdigest(token),
        password_reset_sent_at: Time.current
      )
      Success(token)
    end
  end
end
```

#### `PasswordResets::ExecuteReset`
```ruby
# app/use_cases/password_resets/execute_reset.rb
module PasswordResets
  class ExecuteReset < ApplicationUseCase
    def call(token:, params:)
      attrs = yield validate(PasswordResets::ResetContract, params)
      user  = yield find_by_token(token)
      _     = yield check_expiry(user)
      _     = yield update_password(user, attrs[:password])
      _     = yield publish(PasswordChanged.new(user_id: user.id))

      Success(user)
    end

    private

    def find_by_token(token)
      digest = Digest::SHA256.hexdigest(token)
      user = User.find_by(password_reset_token: digest)
      user ? Success(user) : Failure([:not_found, "Invalid or expired token"])
    end

    def check_expiry(user)
      if user.password_reset_sent_at < 2.hours.ago
        Failure([:expired, "Token has expired"])
      else
        Success(true)
      end
    end

    def update_password(user, new_password)
      user.update(
        password: new_password,
        password_reset_token: nil,
        password_reset_sent_at: nil
      ) ? Success(user) : Failure([:persistence, user.errors.full_messages])
    end
  end
end
```

**Events:**
```ruby
# app/events/password_changed.rb
class PasswordChanged < BaseEvent
  attribute :user_id, Types::Integer
end
```

**Handler:**
```ruby
# app/event_handlers/invalidate_sessions_on_password_change.rb
class InvalidateSessionsOnPasswordChange
  def self.call(event)
    user = User.find(event.user_id)
    user.remember_tokens.destroy_all
  end
end
```

---

#### `Profiles::UpdateInfo`
```ruby
module Profiles
  class UpdateInfo < ApplicationUseCase
    def call(user:, params:)
      attrs = yield validate(Profiles::UpdateContract, params)
      _     = yield persist(user, attrs)
      _     = yield publish(ProfileUpdated.new(user_id: user.id))

      Success(user.reload)
    end

    private

    def persist(user, attrs)
      user.update(attrs) ? Success(user) : Failure([:persistence, user.errors.full_messages])
    end
  end
end
```

#### `Profiles::ChangePassword`
```ruby
module Profiles
  class ChangePassword < ApplicationUseCase
    def call(user:, params:)
      attrs = yield validate(Profiles::ChangePasswordContract, params)
      _     = yield verify_current(user, attrs[:current_password])
      _     = yield persist(user, attrs[:password])
      _     = yield publish(PasswordChanged.new(user_id: user.id))

      Success(user)
    end

    private

    def verify_current(user, current_password)
      user.authenticate(current_password) ? Success(true) : Failure([:unauthorized, "Current password is incorrect"])
    end

    def persist(user, new_password)
      user.update(password: new_password) ? Success(user) : Failure([:persistence, user.errors.full_messages])
    end
  end
end
```

---

### 4.2 Bounded Context: Trading (Portafolio, Posiciones, Watchlist)

> Watchlist se fusiono en este BC — es parte de la experiencia de trading del usuario.

#### `Dashboard::Assemble`
```ruby
# app/use_cases/dashboard/assemble.rb
module Dashboard
  class Assemble < ApplicationUseCase
    def call(user:, currency: "USD")
      portfolio  = yield load_portfolio(user)
      summary    = yield build_summary(portfolio, currency)
      watchlist  = yield load_watchlist(user)
      news       = yield load_news(user)
      trending   = yield load_trending
      indices    = yield load_market_status
      sentiment  = yield calculate_sentiment(user)

      Success({
        user:, summary:, watchlist:, news:,
        trending:, indices:, sentiment:
      })
    end

    private

    def load_portfolio(user)
      user.portfolio ? Success(user.portfolio) : Failure([:not_found, "Portfolio not found"])
    end

    def build_summary(portfolio, currency)
      Success(PortfolioSummary.new(portfolio, currency:).to_h)
    end

    def load_watchlist(user)
      items = user.watchlist_items.includes(asset: :trend_scores).limit(10)
      Success(items)
    end

    def load_news(user)
      tickers = user.watchlist_items.joins(:asset).pluck("assets.symbol")
      articles = if tickers.any?
                   NewsArticle.where(related_ticker: tickers).or(NewsArticle.recent).distinct.limit(5)
                 else
                   NewsArticle.recent
                 end
      Success(articles)
    end

    def load_trending
      Success(Asset.order(change_percent_24h: :desc).limit(5))
    end

    def load_market_status
      Success(MarketIndex.major)
    end

    def calculate_sentiment(user)
      Success(MarketSentiment.for_user(user))
    end
  end
end
```

---

#### `Portfolio::LoadOverview`
```ruby
module Portfolio
  class LoadOverview < ApplicationUseCase
    def call(user:, currency: "USD", tab: "open")
      portfolio  = yield load_portfolio(user)
      positions  = yield load_positions(portfolio, tab)
      summary    = yield build_summary(portfolio, currency)
      allocation = yield build_allocation(portfolio)
      dividends  = yield load_dividends(portfolio) if tab == "dividends"

      Success({
        portfolio:, positions:, summary:, allocation:, tab:,
        dividends: dividends || []
      })
    end

    private

    def load_portfolio(user)
      user.portfolio ? Success(user.portfolio) : Failure([:not_found, "Portfolio not found"])
    end

    def load_positions(portfolio, tab)
      scope = case tab
              when "closed" then portfolio.closed_positions
              else portfolio.open_positions
              end
      Success(scope.includes(:asset))
    end

    def build_summary(portfolio, currency)
      Success(PortfolioSummary.new(portfolio, currency:).to_h)
    end

    def build_allocation(portfolio)
      Success(portfolio.allocation_by_sector)
    end

    def load_dividends(portfolio)
      Success(portfolio.dividend_payments.includes(dividend: :asset).order(created_at: :desc))
    end
  end
end
```

---

#### `Trades::ExecuteTrade`
```ruby
# app/use_cases/trades/execute_trade.rb
module Trades
  class ExecuteTrade < ApplicationUseCase
    def call(user:, params:)
      attrs     = yield validate(Trades::CreateContract, params)
      portfolio = yield load_portfolio(user)
      asset     = yield find_asset(attrs[:asset_symbol])
      trade     = yield persist_trade(portfolio, asset, attrs)
      position  = yield update_position(portfolio, asset, trade, attrs)
      _         = yield publish(TradeExecuted.new(
                    user_id: user.id, trade_id: trade.id,
                    asset_symbol: asset.symbol, side: attrs[:side]
                  ))

      Success({ trade:, position: })
    end

    private

    def load_portfolio(user)
      user.portfolio ? Success(user.portfolio) : Failure([:not_found, "No portfolio"])
    end

    def find_asset(symbol)
      asset = Asset.find_by(symbol: symbol.upcase)
      asset ? Success(asset) : Failure([:not_found, "Asset #{symbol} not found"])
    end

    def persist_trade(portfolio, asset, attrs)
      trade = portfolio.trades.build(
        asset:,
        side: attrs[:side],
        shares: attrs[:shares],
        price_per_share: attrs[:price_per_share],
        fee: attrs[:fee] || 0,
        currency: attrs[:currency] || "USD",
        executed_at: Time.current
      )
      trade.save ? Success(trade) : Failure([:persistence, trade.errors.full_messages])
    end

    def update_position(portfolio, asset, trade, attrs)
      if attrs[:side] == "buy"
        position = portfolio.positions.find_or_initialize_by(asset: asset, status: :open)
        position.shares = (position.shares || 0) + trade.shares
        position.currency = trade.currency
        position.opened_at ||= Time.current
        position.save!
        trade.update!(position: position)
        position.recalculate_avg_cost!
        Success(position)
      else
        position = portfolio.positions.open.find_by(asset: asset)
        return Failure([:not_found, "No open position for #{asset.symbol}"]) unless position
        position.shares -= trade.shares
        if position.shares <= 0
          position.update!(status: :closed, closed_at: Time.current, shares: 0)
        else
          position.save!
          position.recalculate_avg_cost!
        end
        trade.update!(position: position)
        Success(position)
      end
    end
  end
end
```

**Contract:**
```ruby
# app/contracts/trades/create_contract.rb
module Trades
  class CreateContract < ApplicationContract
    params do
      required(:asset_symbol).filled(:string)
      required(:side).filled(:string, included_in?: %w[buy sell])
      required(:shares).filled(:decimal, gt?: 0)
      required(:price_per_share).filled(:decimal, gt?: 0)
      optional(:fee).filled(:decimal, gteq?: 0)
      optional(:currency).filled(:string)
    end
  end
end
```

**Event:**
```ruby
# app/events/trade_executed.rb
class TradeExecuted < BaseEvent
  attribute :user_id,      Types::Integer
  attribute :trade_id,     Types::Integer
  attribute :asset_symbol, Types::String
  attribute :side,         Types::String
end
```

**Handlers:**
```ruby
# app/event_handlers/recalculate_avg_cost_on_trade.rb
class RecalculateAvgCostOnTrade
  def self.call(event)
    trade = Trade.find(event.trade_id)
    trade.position&.recalculate_avg_cost!
  end
end

# app/event_handlers/log_trade_activity.rb
class LogTradeActivity
  def self.call(event)
    AuditLog.create!(
      user_id: event.user_id,
      action: "trading.#{event.side}",
      changes: { asset: event.asset_symbol, trade_id: event.trade_id }
    )
  end
end
```

---

#### `Positions::OpenPosition` (simplificado — usa ExecuteTrade internamente)
```ruby
module Positions
  class OpenPosition < ApplicationUseCase
    def call(user:, params:)
      Trades::ExecuteTrade.call(
        user:,
        params: params.merge(side: "buy")
      )
    end
  end
end
```

#### `Positions::ClosePosition`
```ruby
module Positions
  class ClosePosition < ApplicationUseCase
    def call(user:, position_id:, params: {})
      position = yield find_position(user, position_id)

      Trades::ExecuteTrade.call(
        user:,
        params: {
          asset_symbol: position.asset.symbol,
          side: "sell",
          shares: params[:shares] || position.shares,
          price_per_share: params[:price_per_share] || position.asset.current_price
        }
      )
    end

    private

    def find_position(user, position_id)
      position = user.portfolio.positions.open.find_by(id: position_id)
      position ? Success(position) : Failure([:not_found, "Position not found"])
    end
  end
end
```

---

#### `Watchlist::AddAsset`
```ruby
module Watchlist
  class AddAsset < ApplicationUseCase
    def call(user:, asset_id:)
      asset = yield find_asset(asset_id)
      item  = yield persist(user, asset)
      _     = yield publish(WatchlistItemAdded.new(user_id: user.id, asset_id: asset.id))

      Success(item)
    end

    private

    def find_asset(asset_id)
      asset = Asset.find_by(id: asset_id)
      asset ? Success(asset) : Failure([:not_found, "Asset not found"])
    end

    def persist(user, asset)
      item = user.watchlist_items.build(asset:)
      item.save ? Success(item) : Failure([:persistence, item.errors.full_messages])
    end
  end
end
```

#### `Watchlist::RemoveAsset`
```ruby
module Watchlist
  class RemoveAsset < ApplicationUseCase
    def call(user:, asset_id:)
      item = yield find_item(user, asset_id)
      _    = yield destroy(item)

      Success(asset_id)
    end

    private

    def find_item(user, asset_id)
      item = user.watchlist_items.find_by(asset_id:)
      item ? Success(item) : Failure([:not_found, "Not in watchlist"])
    end

    def destroy(item)
      item.destroy ? Success(true) : Failure([:persistence, "Could not remove"])
    end
  end
end
```

---

#### `Snapshots::TakePortfolioSnapshot`
```ruby
# app/use_cases/snapshots/take_portfolio_snapshot.rb
module Snapshots
  class TakePortfolioSnapshot < ApplicationUseCase
    def call(portfolio:)
      snapshot = yield create_snapshot(portfolio)
      _        = yield publish(PortfolioSnapshotTaken.new(portfolio_id: portfolio.id, date: Date.current.to_s))

      Success(snapshot)
    end

    private

    def create_snapshot(portfolio)
      invested = portfolio.open_positions.sum { |p| p.market_value }
      snapshot = portfolio.snapshots.create(
        date: Date.current,
        total_value: invested + portfolio.buying_power,
        cash_value: portfolio.buying_power,
        invested_value: invested
      )
      snapshot.persisted? ? Success(snapshot) : Failure([:persistence, snapshot.errors.full_messages])
    end
  end
end
```

---

### 4.3 Bounded Context: Alerts

#### `Alerts::CreateRule`
```ruby
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
```

**Contract:**
```ruby
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
```

#### `Alerts::UpdateRule`
```ruby
module Alerts
  class UpdateRule < ApplicationUseCase
    def call(user:, rule_id:, params:)
      attrs = yield validate(Alerts::UpdateContract, params)
      rule  = yield find_rule(user, rule_id)
      _     = yield persist(rule, attrs)

      Success(rule.reload)
    end

    private

    def find_rule(user, rule_id)
      rule = user.alert_rules.find_by(id: rule_id)
      rule ? Success(rule) : Failure([:not_found, "Alert rule not found"])
    end

    def persist(rule, attrs)
      rule.update(attrs) ? Success(rule) : Failure([:persistence, rule.errors.full_messages])
    end
  end
end
```

#### `Alerts::ToggleRule`
```ruby
module Alerts
  class ToggleRule < ApplicationUseCase
    def call(user:, rule_id:)
      rule = yield find_rule(user, rule_id)
      _    = yield toggle(rule)

      Success(rule)
    end

    private

    def find_rule(user, rule_id)
      rule = user.alert_rules.find_by(id: rule_id)
      rule ? Success(rule) : Failure([:not_found, "Alert rule not found"])
    end

    def toggle(rule)
      new_status = rule.active? ? :paused : :active
      rule.update(status: new_status) ? Success(rule) : Failure([:persistence, "Could not toggle"])
    end
  end
end
```

#### `Alerts::DestroyRule`
```ruby
module Alerts
  class DestroyRule < ApplicationUseCase
    def call(user:, rule_id:)
      rule = yield find_rule(user, rule_id)
      _    = yield destroy(rule)

      Success(rule_id)
    end

    private

    def find_rule(user, rule_id)
      rule = user.alert_rules.find_by(id: rule_id)
      rule ? Success(rule) : Failure([:not_found, "Alert rule not found"])
    end

    def destroy(rule)
      rule.destroy ? Success(true) : Failure([:persistence, "Could not delete"])
    end
  end
end
```

#### `Alerts::UpdatePreferences`
```ruby
module Alerts
  class UpdatePreferences < ApplicationUseCase
    def call(user:, params:)
      attrs = yield validate(Alerts::PreferencesContract, params)
      pref  = yield load_preferences(user)
      _     = yield persist(pref, attrs)

      Success(pref.reload)
    end

    private

    def load_preferences(user)
      pref = user.alert_preference
      pref ? Success(pref) : Failure([:not_found, "Preferences not found"])
    end

    def persist(pref, attrs)
      pref.update(attrs) ? Success(pref) : Failure([:persistence, "Could not update"])
    end
  end
end
```

#### `Alerts::EvaluateRules`
```ruby
# app/use_cases/alerts/evaluate_rules.rb
module Alerts
  class EvaluateRules < ApplicationUseCase
    def call(asset:, new_price:)
      rules     = yield load_active_rules(asset.symbol)
      triggered = yield evaluate(rules, asset, new_price)

      triggered.each do |rule|
        publish(AlertRuleTriggered.new(
          rule_id: rule.id, user_id: rule.user_id,
          asset_symbol: asset.symbol, price: new_price.to_s
        ))
      end

      Success(triggered)
    end

    private

    def load_active_rules(symbol)
      Success(AlertRule.where(asset_symbol: symbol, status: :active))
    end

    def evaluate(rules, asset, new_price)
      triggered = AlertEvaluator.evaluate(rules, asset, new_price)
      Success(triggered)
    end
  end
end
```

---

### 4.4 Bounded Context: Market Data

#### `Market::ExploreAssets`
```ruby
module Market
  class ExploreAssets < ApplicationUseCase
    def call(params: {})
      filters  = yield validate(Market::ExploreContract, params)
      assets   = yield query(filters)
      indices  = yield load_indices

      Success({ assets:, indices: })
    end

    private

    def query(filters)
      scope = Asset.where(asset_type: [:stock, :crypto])
      scope = scope.by_sector(filters[:sector])                         if filters[:sector].present?
      scope = scope.where(exchange: filters[:exchange])                 if filters[:exchange].present?
      scope = scope.where("market_cap >= ?", min_cap(filters[:market_cap])) if filters[:market_cap].present?
      scope = scope.where("symbol ILIKE ? OR name ILIKE ?", "%#{filters[:q]}%", "%#{filters[:q]}%") if filters[:q].present?

      Success(scope.order(:symbol))
    end

    def load_indices
      Success(MarketIndex.major)
    end

    def min_cap(tier)
      case tier
      when "large" then 10_000_000_000
      when "mid"   then 2_000_000_000
      when "small" then 0
      else 0
      end
    end
  end
end
```

#### `Market::ExportCsv`
```ruby
module Market
  class ExportCsv < ApplicationUseCase
    def call(user:, params: {})
      result = yield ExploreAssets.call(params:)
      csv    = yield generate(result[:assets])
      _      = yield publish(CsvExported.new(user_id: user.id, export_type: "market_assets"))

      Success(csv)
    end

    private

    def generate(assets_scope)
      csv = CSV.generate(headers: true) do |csv|
        csv << %w[Symbol Name Price Change_24h Sector Exchange]
        assets_scope.find_each do |asset|
          csv << [asset.symbol, asset.name, asset.current_price, asset.change_percent_24h, asset.sector, asset.exchange]
        end
      end
      Success(csv)
    end
  end
end
```

---

#### `Earnings::ListForMonth`
```ruby
module Earnings
  class ListForMonth < ApplicationUseCase
    def call(user:, date:, filter: "all")
      events    = yield load_events(date)
      events    = yield apply_filter(user, events, filter)
      watchlist = yield load_watchlist_events(user, date)

      Success({ events:, watchlist:, date: })
    end

    private

    def load_events(date)
      Success(EarningsEvent.for_month(date).includes(:asset))
    end

    def apply_filter(user, events, filter)
      return Success(events) unless filter == "watchlist"
      watched_ids = user.watchlist_items.pluck(:asset_id)
      Success(events.where(asset_id: watched_ids))
    end

    def load_watchlist_events(user, date)
      watched_ids = user.watchlist_items.pluck(:asset_id)
      Success(EarningsEvent.for_month(date).where(asset_id: watched_ids).includes(:asset).order(:report_date))
    end
  end
end
```

---

#### `Trends::LoadAssetTrend`
```ruby
module Trends
  class LoadAssetTrend < ApplicationUseCase
    def call(params: {})
      asset    = yield find_asset(params[:symbol])
      score    = yield load_trend_score(asset)
      earnings = yield load_next_earnings(asset)
      history  = yield load_price_history(asset, params[:period] || "1Y")

      Success({ asset:, score:, earnings:, history: })
    end

    private

    def find_asset(symbol)
      asset = symbol.present? ? Asset.find_by(symbol: symbol.upcase) : Asset.joins(:trend_scores).order("trend_scores.score DESC").first
      asset ? Success(asset) : Failure([:not_found, "Asset not found"])
    end

    def load_trend_score(asset)
      Success(asset.latest_trend_score)
    end

    def load_next_earnings(asset)
      Success(asset.earnings_events.upcoming.first)
    end

    def load_price_history(asset, period)
      from = case period
             when "1M" then 1.month.ago
             when "3M" then 3.months.ago
             when "1Y" then 1.year.ago
             when "5Y" then 5.years.ago
             else 1.year.ago
             end
      Success(asset.asset_price_histories.for_period(from.to_date, Date.current))
    end
  end
end
```

---

### 4.5 Bounded Context: Administration

#### `Admin::Assets::CreateAsset`
```ruby
module Admin
  module Assets
    class CreateAsset < ApplicationUseCase
      def call(admin:, params:)
        attrs = yield validate(Admin::Assets::CreateContract, params)
        asset = yield persist(attrs)
        _     = yield audit(admin, asset)

        Success(asset)
      end

      private

      def persist(attrs)
        asset = Asset.new(attrs)
        asset.save ? Success(asset) : Failure([:persistence, asset.errors.full_messages])
      end

      def audit(admin, asset)
        AuditLog.create!(user: admin, action: "admin.assets.create", auditable: asset, changes: { after: { symbol: asset.symbol } })
        Success(true)
      end
    end
  end
end
```

#### `Admin::Assets::ToggleStatus`
```ruby
module Admin
  module Assets
    class ToggleStatus < ApplicationUseCase
      def call(admin:, asset_id:)
        asset      = yield find_asset(asset_id)
        old_status = asset.sync_status
        _          = yield toggle(asset)
        _          = yield audit(admin, asset, old_status)

        Success(asset)
      end

      private

      def find_asset(asset_id)
        asset = Asset.find_by(id: asset_id)
        asset ? Success(asset) : Failure([:not_found, "Asset not found"])
      end

      def toggle(asset)
        new_status = asset.active? ? :disabled : :active
        asset.update(sync_status: new_status) ? Success(asset) : Failure([:persistence, "Could not toggle"])
      end

      def audit(admin, asset, old_status)
        AuditLog.create!(
          user: admin, action: "admin.assets.toggle_status", auditable: asset,
          changes: { before: { sync_status: old_status }, after: { sync_status: asset.sync_status } }
        )
        Success(true)
      end
    end
  end
end
```

#### `Admin::Assets::TriggerSync`
```ruby
module Admin
  module Assets
    class TriggerSync < ApplicationUseCase
      def call(asset_id: nil)
        if asset_id
          asset = yield find_asset(asset_id)
          SyncSingleAssetJob.perform_later(asset.id)
        else
          SyncAllAssetsJob.perform_later
        end

        Success(:sync_enqueued)
      end

      private

      def find_asset(asset_id)
        asset = Asset.find_by(id: asset_id)
        asset ? Success(asset) : Failure([:not_found, "Asset not found"])
      end
    end
  end
end
```

#### `Admin::Users::SuspendUser`
```ruby
module Admin
  module Users
    class SuspendUser < ApplicationUseCase
      def call(admin:, user_id:)
        user = yield find_user(user_id)
        _    = yield check_not_admin(user)
        _    = yield suspend(user)
        _    = yield audit(admin, user)
        _    = yield publish(UserSuspended.new(user_id: user.id, email: user.email))

        Success(user)
      end

      private

      def find_user(user_id)
        user = User.find_by(id: user_id)
        user ? Success(user) : Failure([:not_found, "User not found"])
      end

      def check_not_admin(user)
        user.admin? ? Failure([:forbidden, "Cannot suspend admin"]) : Success(true)
      end

      def suspend(user)
        user.update(status: :suspended) ? Success(user) : Failure([:persistence, "Could not suspend"])
      end

      def audit(admin, user)
        AuditLog.create!(
          user: admin, action: "admin.users.suspend", auditable: user,
          changes: { after: { status: "suspended" } }
        )
        Success(true)
      end
    end
  end
end
```

#### `Admin::Integrations::ConnectProvider`
```ruby
module Admin
  module Integrations
    class ConnectProvider < ApplicationUseCase
      def call(admin:, params:)
        attrs       = yield validate(Admin::Integrations::CreateContract, params)
        integration = yield persist(attrs)
        _           = yield audit(admin, integration)
        _           = yield publish(IntegrationConnected.new(provider: integration.provider_name))

        Success(integration)
      end

      private

      def persist(attrs)
        integration = Integration.new(attrs.merge(connection_status: :connected, last_sync_at: Time.current))
        integration.save ? Success(integration) : Failure([:persistence, integration.errors.full_messages])
      end

      def audit(admin, integration)
        AuditLog.create!(user: admin, action: "admin.integrations.connect", auditable: integration)
        Success(true)
      end
    end
  end
end
```

#### `Admin::Integrations::RefreshSync`
```ruby
module Admin
  module Integrations
    class RefreshSync < ApplicationUseCase
      def call(integration_id:)
        integration = yield find(integration_id)
        _           = yield mark_syncing(integration)

        SyncIntegrationJob.perform_later(integration.id)
        Success(integration)
      end

      private

      def find(integration_id)
        i = Integration.find_by(id: integration_id)
        i ? Success(i) : Failure([:not_found, "Integration not found"])
      end

      def mark_syncing(integration)
        integration.update(connection_status: :syncing) ? Success(integration) : Failure([:persistence, "Error"])
      end
    end
  end
end
```

#### `Admin::Logs::ListLogs`
```ruby
module Admin
  module Logs
    class ListLogs < ApplicationUseCase
      def call(params: {})
        scope = SystemLog.recent
        scope = scope.where(severity: params[:severity])    if params[:severity].present?
        scope = scope.by_module(params[:module_name])       if params[:module_name].present?
        scope = scope.where("created_at >= ?", time_range(params[:time_range])) if params[:time_range].present?
        scope = scope.where("task_name ILIKE ?", "%#{params[:q]}%") if params[:q].present?

        Success(scope)
      end

      private

      def time_range(range)
        case range
        when "1h"  then 1.hour.ago
        when "24h" then 24.hours.ago
        when "7d"  then 7.days.ago
        when "30d" then 30.days.ago
        else 24.hours.ago
        end
      end
    end
  end
end
```

---

### 4.6 Notifications (cross-cutting)

#### `Notifications::CreateNotification`
```ruby
module Notifications
  class CreateNotification < ApplicationUseCase
    def call(user:, title:, body: nil, notification_type: :system, notifiable: nil)
      notification = yield persist(user, title, body, notification_type, notifiable)
      _            = yield publish(NotificationCreated.new(user_id: user.id, notification_id: notification.id))

      Success(notification)
    end

    private

    def persist(user, title, body, notification_type, notifiable)
      n = user.notifications.create(title:, body:, notification_type:, notifiable:)
      n.persisted? ? Success(n) : Failure([:persistence, n.errors.full_messages])
    end
  end
end
```

#### `Notifications::MarkAsRead`
```ruby
module Notifications
  class MarkAsRead < ApplicationUseCase
    def call(user:, notification_id: nil)
      if notification_id
        notification = yield find(user, notification_id)
        notification.mark_as_read!
        Success(notification)
      else
        user.notifications.unread.update_all(read: true)
        Success(:all_read)
      end
    end

    private

    def find(user, notification_id)
      n = user.notifications.find_by(id: notification_id)
      n ? Success(n) : Failure([:not_found, "Notification not found"])
    end
  end
end
```

### 4.7 News Feed

#### `News::ListArticles`
```ruby
# app/use_cases/news/list_articles.rb
module News
  class ListArticles < ApplicationUseCase
    def call(user:, params: {})
      articles = yield query(user, params)

      Success(articles)
    end

    private

    def query(user, params)
      scope = NewsArticle.recent
      scope = scope.for_ticker(params[:ticker])              if params[:ticker].present?
      scope = scope.where("title ILIKE ?", "%#{params[:q]}%") if params[:q].present?

      if params[:filter] == "watchlist"
        tickers = user.watchlist_items.joins(:asset).pluck("assets.symbol")
        scope = scope.where(related_ticker: tickers) if tickers.any?
      end

      Success(scope)
    end
  end
end
```

### 4.8 Global Search

#### `Search::GlobalSearch`
```ruby
# app/use_cases/search/global_search.rb
module Search
  class GlobalSearch < ApplicationUseCase
    def call(user:, query:)
      return Success({ assets: [], alerts: [], news: [] }) if query.blank?

      assets = yield search_assets(query)
      alerts = yield search_alerts(user, query)
      news   = yield search_news(query)

      Success({ assets:, alerts:, news: })
    end

    private

    def search_assets(query)
      Success(
        Asset.where("symbol ILIKE :q OR name ILIKE :q", q: "%#{query}%").limit(5)
      )
    end

    def search_alerts(user, query)
      Success(
        user.alert_rules.where("asset_symbol ILIKE ?", "%#{query}%").limit(5)
      )
    end

    def search_news(query)
      Success(
        NewsArticle.where("title ILIKE ?", "%#{query}%").recent.limit(5)
      )
    end
  end
end
```

### 4.9 Onboarding

#### `Onboarding::CompleteWizard`
```ruby
# app/use_cases/onboarding/complete_wizard.rb
module Onboarding
  class CompleteWizard < ApplicationUseCase
    def call(user:, asset_ids:)
      assets = yield validate_assets(asset_ids)
      _      = yield add_to_watchlist(user, assets)
      _      = yield mark_onboarded(user)

      Success(user)
    end

    private

    def validate_assets(asset_ids)
      assets = Asset.where(id: asset_ids)
      assets.any? ? Success(assets) : Failure([:validation, "Select at least one asset"])
    end

    def add_to_watchlist(user, assets)
      assets.each do |asset|
        user.watchlist_items.find_or_create_by(asset: asset)
      end
      Success(true)
    end

    def mark_onboarded(user)
      # El onboarding se considera completo cuando tiene 3+ watchlist items
      Success(true)
    end
  end
end
```

---

## 5. Domain Services

### 5.1 AlertEvaluator

```ruby
# app/domain/alert_evaluator.rb
class AlertEvaluator
  # Evalua una lista de reglas contra un asset con nuevo precio.
  # Retorna las reglas que se dispararon (puro, sin side effects).
  def self.evaluate(rules, asset, new_price)
    rules.select do |rule|
      case rule.condition
      when "price_crosses_above"
        new_price >= rule.threshold_value && (asset.current_price || 0) < rule.threshold_value
      when "price_crosses_below"
        new_price <= rule.threshold_value && (asset.current_price || 0) > rule.threshold_value
      when "day_change_percent"
        (asset.change_percent_24h || 0).abs >= rule.threshold_value
      when "rsi_overbought"
        # RSI se calcularia desde AssetPriceHistory — placeholder
        false
      when "rsi_oversold"
        false
      else
        false
      end
    end
  end
end
```

### 5.2 MarketSentiment

```ruby
# app/domain/market_sentiment.rb
class MarketSentiment
  # Calcula sentimiento basado en trend scores del watchlist del usuario
  def self.for_user(user)
    scores = user.watched_assets
                 .joins(:trend_scores)
                 .where("trend_scores.calculated_at > ?", 24.hours.ago)
                 .pluck("trend_scores.score")

    return { value: 50, label: "Neutral" } if scores.empty?

    avg = scores.sum.to_f / scores.size
    label = case avg
            when 0..30 then "Bearish"
            when 31..45 then "Slightly Bearish"
            when 46..55 then "Neutral"
            when 56..70 then "Slightly Bullish"
            else "Bullish"
            end

    { value: avg.round, label: }
  end
end
```

### 5.3 PortfolioSummary

```ruby
# app/domain/portfolio_summary.rb
class PortfolioSummary
  def initialize(portfolio, currency: "USD")
    @portfolio = portfolio
    @currency = currency
  end

  def to_h
    {
      total_value: total_value,
      unrealized_gain: unrealized_gain,
      buying_power: @portfolio.buying_power,
      day_gain: day_gain,
      domestic_value: domestic_value,
      international_value: international_value,
      yesterday_value: yesterday_value
    }
  end

  private

  def total_value
    @portfolio.open_positions.sum { |p| p.market_value } + @portfolio.buying_power
  end

  def unrealized_gain
    @portfolio.open_positions.sum { |p| p.total_gain }
  end

  def day_gain
    yesterday = @portfolio.yesterday_snapshot
    return 0 unless yesterday
    total_value - yesterday.total_value
  end

  def domestic_value
    @portfolio.open_positions.domestic.sum { |p| p.market_value }
  end

  def international_value
    @portfolio.open_positions.international.sum { |p| p.market_value }
  end

  def yesterday_value
    @portfolio.yesterday_snapshot&.total_value || total_value
  end
end
```

---

## 6. Domain Events — Registro

```ruby
# config/initializers/event_subscriptions.rb
Rails.application.config.after_initialize do
  # --- User Registered ---
  EventBus.subscribe(UserRegistered, CreatePortfolioOnRegistration)
  EventBus.subscribe(UserRegistered, CreateAlertPreferencesOnRegistration)
  EventBus.subscribe(UserRegistered, SendWelcomeEmailOnRegistration)

  # --- Password Changed ---
  EventBus.subscribe(PasswordChanged, InvalidateSessionsOnPasswordChange)

  # --- Trade Executed ---
  EventBus.subscribe(TradeExecuted, RecalculateAvgCostOnTrade)
  EventBus.subscribe(TradeExecuted, LogTradeActivity)

  # --- Asset Price Updated (el heartbeat del sistema) ---
  EventBus.subscribe(AssetPriceUpdated, EvaluateAlertsOnPriceUpdate)
  EventBus.subscribe(AssetPriceUpdated, BroadcastPriceUpdate)

  # --- Alert Rule Triggered ---
  EventBus.subscribe(AlertRuleTriggered, CreateAlertEventOnTrigger)
  EventBus.subscribe(AlertRuleTriggered, CreateNotificationOnAlert)

  # --- Notification Created ---
  EventBus.subscribe(NotificationCreated, BroadcastNotification)

  # --- User Suspended ---
  EventBus.subscribe(UserSuspended, SendSuspensionEmail)

  # --- Integration Connected ---
  EventBus.subscribe(IntegrationConnected, LogIntegrationConnected)

  # --- CSV Exported ---
  EventBus.subscribe(CsvExported, CreateAuditLog)
end
```

### Event: AssetPriceUpdated (el mas importante del sistema)

```ruby
# app/events/asset_price_updated.rb
class AssetPriceUpdated < BaseEvent
  attribute :asset_id,  Types::Integer
  attribute :symbol,    Types::String
  attribute :old_price, Types::String
  attribute :new_price, Types::String
end

# app/event_handlers/evaluate_alerts_on_price_update.rb
class EvaluateAlertsOnPriceUpdate
  def self.async? = true

  def self.call(event)
    asset = Asset.find(event.asset_id)
    Alerts::EvaluateRules.call(asset: asset, new_price: BigDecimal(event.new_price))
  end
end

# app/event_handlers/broadcast_price_update.rb
class BroadcastPriceUpdate
  def self.call(event)
    Turbo::StreamsChannel.broadcast_replace_to(
      "asset_#{event.asset_id}",
      target: "asset_price_#{event.asset_id}",
      partial: "components/asset_price",
      locals: { asset: Asset.find(event.asset_id) }
    )
  end
end
```

### Event: AlertRuleTriggered

```ruby
# app/events/alert_rule_triggered.rb
class AlertRuleTriggered < BaseEvent
  attribute :rule_id,      Types::Integer
  attribute :user_id,      Types::Integer
  attribute :asset_symbol, Types::String
  attribute :price,        Types::String
end

# app/event_handlers/create_alert_event_on_trigger.rb
class CreateAlertEventOnTrigger
  def self.call(event)
    rule = AlertRule.find(event.rule_id)
    AlertEvent.create!(
      alert_rule: rule, user_id: event.user_id,
      asset_symbol: event.asset_symbol,
      message: "#{rule.condition.humanize}: #{event.asset_symbol} at $#{event.price}",
      event_status: :triggered, triggered_at: Time.current
    )
  end
end

# app/event_handlers/create_notification_on_alert.rb
class CreateNotificationOnAlert
  def self.async? = true

  def self.call(event)
    user = User.find(event.user_id)
    Notifications::CreateNotification.call(
      user: user,
      title: "#{event.asset_symbol} alert triggered",
      body: "Price reached $#{event.price}",
      notification_type: :alert_triggered
    )
  end
end

# app/event_handlers/broadcast_notification.rb
class BroadcastNotification
  def self.call(event)
    user = User.find(event.user_id)
    Turbo::StreamsChannel.broadcast_prepend_to(
      "notifications_#{event.user_id}",
      target: "notification_list",
      partial: "shared/notification",
      locals: { notification: Notification.find(event.notification_id) }
    )
    # Actualizar badge counter
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications_#{event.user_id}",
      target: "notification_badge",
      partial: "shared/notification_badge",
      locals: { count: user.notifications.unread.count }
    )
  end
end
```

---

## 7. Controller ↔ Use Case Mapping

| Controller | Action | Use Case | Turbo Response |
|------------|--------|----------|----------------|
| `SessionsController` | `create` | `Sessions::Authenticate` | Redirect → dashboard |
| `SessionsController` | `destroy` | (inline logout) | Redirect → root |
| `RegistrationsController` | `create` | `Registrations::RegisterUser` | Redirect → dashboard |
| `PasswordResetsController` | `create` | `PasswordResets::RequestReset` | Flash + redirect |
| `PasswordResetsController` | `update` | `PasswordResets::ExecuteReset` | Redirect → login |
| `DashboardController` | `show` | `Dashboard::Assemble` | Full page |
| `MarketController` | `index` | `Market::ExploreAssets` | Turbo Frame `market_listings` |
| `MarketController` | `export` | `Market::ExportCsv` | CSV download |
| `PortfolioController` | `show` | `Portfolio::LoadOverview` | Turbo Frame `positions_tab` |
| `AlertsController` | `index` | (load data) | Full page |
| `AlertsController` | `create` | `Alerts::CreateRule` | Turbo Stream prepend |
| `AlertsController` | `update` | `Alerts::UpdateRule` | Turbo Stream replace |
| `AlertsController` | `toggle` | `Alerts::ToggleRule` | Turbo Stream replace |
| `AlertsController` | `destroy` | `Alerts::DestroyRule` | Turbo Stream remove |
| `EarningsController` | `index` | `Earnings::ListForMonth` | Turbo Frame `calendar_grid` |
| `ProfileController` | `show` | (load user) | Full page |
| `ProfileController` | `update` | `Profiles::UpdateInfo` | Turbo Stream replace |
| `WatchlistController` | `create` | `Watchlist::AddAsset` | Turbo Stream append |
| `WatchlistController` | `destroy` | `Watchlist::RemoveAsset` | Turbo Stream remove |
| `TrendsController` | `index` | `Trends::LoadAssetTrend` | Turbo Frame |
| `NotificationsController` | `index` | (load notifications) | Turbo Frame dropdown |
| `NotificationsController` | `update` | `Notifications::MarkAsRead` | Turbo Stream replace |
| `Admin::AssetsController` | `index` | (load scope) | Full page |
| `Admin::AssetsController` | `create` | `Admin::Assets::CreateAsset` | Turbo Stream prepend |
| `Admin::AssetsController` | `toggle` | `Admin::Assets::ToggleStatus` | Turbo Stream replace |
| `Admin::AssetsController` | `sync` | `Admin::Assets::TriggerSync` | Flash notice |
| `Admin::UsersController` | `index` | (load scope) | Full page |
| `Admin::UsersController` | `suspend` | `Admin::Users::SuspendUser` | Turbo Stream replace |
| `Admin::LogsController` | `index` | `Admin::Logs::ListLogs` | Turbo Frame `logs_table` |

---

## 8. Gateways (Output Ports para APIs externas)

```ruby
# app/gateways/market_data_gateway.rb (Interface / Port)
class MarketDataGateway
  def fetch_price(symbol)
    raise NotImplementedError
  end

  def fetch_bulk_prices(symbols)
    raise NotImplementedError
  end
end

# app/gateways/polygon_gateway.rb (Adapter)
class PolygonGateway < MarketDataGateway
  BASE_URL = "https://api.polygon.io/v2"
  TIMEOUT = 5  # segundos

  def initialize(api_key: nil)
    @api_key = api_key || Rails.application.credentials.polygon_api_key
  end

  def fetch_price(symbol)
    # Implementacion real contra Polygon.io
    # Por ahora retorna hardcoded
    Success({ symbol:, price: 189.43, change: 2.45 })
  rescue => e
    Failure([:gateway_error, e.message])
  end

  def fetch_bulk_prices(symbols)
    symbols.map { |s| fetch_price(s) }
  end

  include Dry::Monads[:result]
end

# app/gateways/coingecko_gateway.rb (Adapter)
class CoingeckoGateway < MarketDataGateway
  def fetch_price(symbol)
    Success({ symbol:, price: 64231.00, change: 0.85 })
  rescue => e
    Failure([:gateway_error, e.message])
  end

  include Dry::Monads[:result]
end

# app/gateways/fx_rates_gateway.rb (Adapter)
class FxRatesGateway
  include Dry::Monads[:result]

  def refresh_rates(base: "USD", targets: %w[EUR MXN GBP TWD])
    # Llamar a API externa (ej: exchangerate-api.com)
    # Por ahora hardcodeado
    rates = { "EUR" => 0.92, "MXN" => 17.25, "GBP" => 0.79, "TWD" => 31.50 }

    targets.each do |target|
      next unless rates[target]
      FxRate.upsert(
        { base_currency: base, quote_currency: target, rate: rates[target], fetched_at: Time.current },
        unique_by: [:base_currency, :quote_currency]
      )
    end

    Success(:rates_refreshed)
  rescue => e
    Failure([:gateway_error, e.message])
  end
end
```

---

## 9. Resumen de Bounded Contexts

| Bounded Context | Use Cases | Events | Entities |
|-----------------|-----------|--------|----------|
| **Identity** | Authenticate, RegisterUser, RequestReset, ExecuteReset, UpdateInfo, ChangePassword | UserRegistered, PasswordChanged, ProfileUpdated | User, AlertPreference, RememberToken |
| **Trading** | Assemble Dashboard, LoadOverview, OpenPosition, ClosePosition, ExecuteTrade, AddAsset, RemoveAsset, TakePortfolioSnapshot, CompleteWizard (Onboarding) | PositionOpened, PositionClosed, TradeExecuted, WatchlistItemAdded, PortfolioSnapshotTaken | Portfolio, Position, Trade, WatchlistItem, PortfolioSnapshot, DividendPayment |
| **Alerts** | CreateRule, UpdateRule, ToggleRule, DestroyRule, UpdatePreferences, EvaluateRules, CreateNotification, MarkAsRead | AlertRuleCreated, AlertRuleTriggered, NotificationCreated | AlertRule, AlertEvent, Notification |
| **Market Data** | ExploreAssets, ExportCsv, ListForMonth, LoadAssetTrend, ListArticles, GlobalSearch | AssetPriceUpdated, FxRatesRefreshed, CsvExported | Asset, TrendScore, EarningsEvent, MarketIndex, NewsArticle, AssetPriceHistory, FxRate, Dividend |
| **Administration** | CreateAsset, ToggleStatus, TriggerSync, SuspendUser, ConnectProvider, RefreshSync, ListLogs, ExportCsv | UserSuspended, IntegrationConnected | SystemLog, Integration, AuditLog |
