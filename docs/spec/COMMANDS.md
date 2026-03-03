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

## 2. Estructura de Carpetas (Hexagonal por Bounded Context)

```
app/
├── contexts/                          # BOUNDED CONTEXTS — Logica de negocio
│   ├── identity/                      # BC: Identity (auth, profiles, onboarding)
│   │   ├── contracts/                 # Identity::Contracts::* (LoginContract, RegisterContract, etc.)
│   │   ├── events/                    # Identity::Events::* (UserRegistered, PasswordChanged, etc.)
│   │   ├── handlers/                  # Identity::Handlers::* (CreatePortfolioOnRegistration, etc.)
│   │   └── use_cases/                 # Identity::UseCases::* (Login, Register, ChangePassword, etc.)
│   │
│   ├── trading/                       # BC: Trading (portfolio, trades, watchlist, dashboard)
│   │   ├── contracts/                 # Trading::Contracts::* (ExecuteTradeContract, etc.)
│   │   ├── domain/                    # Trading::Domain::* (PortfolioSummary, SplitAdjuster, etc.)
│   │   ├── events/                    # Trading::Events::* (TradeExecuted, SplitDetected, etc.)
│   │   ├── handlers/                  # Trading::Handlers::* (RecalculateAvgCostOnTrade, etc.)
│   │   └── use_cases/                 # Trading::UseCases::* (AssembleDashboard, ExecuteTrade, etc.)
│   │
│   ├── alerts/                        # BC: Alerts (rules, evaluation, triggering)
│   │   ├── contracts/                 # Alerts::Contracts::* (CreateContract)
│   │   ├── domain/                    # Alerts::Domain::* (AlertEvaluator)
│   │   ├── events/                    # Alerts::Events::* (AlertRuleCreated, AlertRuleTriggered)
│   │   ├── handlers/                  # Alerts::Handlers::* (EvaluateAlertsOnPriceUpdate, etc.)
│   │   └── use_cases/                 # Alerts::UseCases::* (CreateRule, EvaluateRules, etc.)
│   │
│   ├── market_data/                   # BC: Market Data (prices, gateways, fundamentals, news)
│   │   ├── domain/                    # MarketData::Domain::* (MarketSentiment, TrendScoreCalculator)
│   │   ├── events/                    # MarketData::Events::* (AssetPriceUpdated, NewsSynced, etc.)
│   │   ├── gateways/                  # MarketData::Gateways::* (PolygonGateway, CoinGeckoGateway, etc.)
│   │   ├── handlers/                  # MarketData::Handlers::* (BroadcastPriceUpdate, etc.)
│   │   └── use_cases/                 # MarketData::UseCases::* (ExploreAssets, ListEarnings, etc.)
│   │
│   ├── administration/                # BC: Administration (admin ops, integrations, logs)
│   │   ├── contracts/                 # Administration::Contracts::* (nested: Assets::, Integrations::)
│   │   ├── events/                    # Administration::Events::* (IntegrationConnected, CsvExported)
│   │   ├── handlers/                  # Administration::Handlers::* (LogIntegrationConnected, etc.)
│   │   └── use_cases/                 # Administration::UseCases::* (nested: Assets::, Users::, etc.)
│   │
│   └── notifications/                 # BC: Notifications (creation, delivery)
│       ├── events/                    # Notifications::Events::* (NotificationCreated)
│       ├── handlers/                  # Notifications::Handlers::* (BroadcastNotification)
│       └── use_cases/                 # Notifications::UseCases::* (CreateNotification, MarkAsRead)
│
├── shared/                            # CROSS-CUTTING — No namespace prefix
│   ├── base/                          # ApplicationUseCase, ApplicationContract
│   ├── domain/                        # CircuitBreaker, RateLimiter, GatewayChain, etc.
│   ├── events/                        # BaseEvent, EventBus
│   └── types/                         # Types (Dry::Types)
│
├── models/                            # ActiveRecord Entities (driven adapter)
├── controllers/                       # Driving Adapters (HTTP)
├── views/                             # Presentacion
└── javascript/controllers/            # Stimulus
```

> **Naming:** Organizational folders map to Ruby modules.
> `app/contexts/alerts/use_cases/create_rule.rb` → `Alerts::UseCases::CreateRule`
> Shared folders are collapsed: `app/shared/domain/circuit_breaker.rb` → `CircuitBreaker`

---

## 3. Base Classes

### 3.1 Application Use Case

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

### 3.2 Application Contract

```ruby
# app/shared/base/application_contract.rb
class ApplicationContract < Dry::Validation::Contract
  config.messages.backend = :i18n
end
```

### 3.3 Base Event

```ruby
# app/shared/events/base_event.rb
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
# app/shared/events/event_bus.rb
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
# app/shared/types/types.rb
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

#### `Identity::UseCases::Login`
```ruby
# app/contexts/identity/use_cases/login.rb
module Identity
  module UseCases
    class Login < ApplicationUseCase
      def call(params:)
        attrs = yield validate(Identity::Contracts::LoginContract, params)
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
end
```

**Contract:**
```ruby
# app/contexts/identity/contracts/login_contract.rb
module Identity
  module Contracts
    class LoginContract < ApplicationContract
    params do
      required(:email).filled(:string)
        required(:password).filled(:string)
      end
    end
  end
end
```

---

#### `Identity::UseCases::Register`
```ruby
# app/contexts/identity/use_cases/register.rb
module Identity
  module UseCases
    class Register < ApplicationUseCase
      def call(params:)
        attrs = yield validate(Identity::Contracts::RegisterContract, params)
        user  = yield persist(attrs)
        _     = yield publish(Events::UserRegistered.new(user_id: user.id, email: user.email))

      Success(user)
    end

    private

      def persist(attrs)
        user = User.new(attrs.merge(role: :user))
        user.save ? Success(user) : Failure([:persistence, user.errors.full_messages])
      end
    end
  end
end
```

**Contract:**
```ruby
# app/contexts/identity/contracts/register_contract.rb
module Identity
  module Contracts
    class RegisterContract < ApplicationContract
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
end
```

**Event:**
```ruby
# app/contexts/identity/events/user_registered.rb
module Identity
  module Events
    class UserRegistered < BaseEvent
      attribute :user_id, Types::Integer
      attribute :email,   Types::String
    end
  end
end
```

**Event Handlers:**
```ruby
# app/contexts/identity/handlers/create_portfolio_on_registration.rb
module Identity
  module Handlers
    class CreatePortfolioOnRegistration
      def self.call(event)
    user = User.find(event.user_id)
        user.create_portfolio!(inception_date: Date.current)
      end
    end
  end
end

# app/contexts/identity/handlers/create_alert_preferences_on_registration.rb
module Identity
  module Handlers
    class CreateAlertPreferencesOnRegistration
      def self.call(event)
        user = User.find(event.user_id)
        user.create_alert_preference!
      end
    end
  end
end

# app/contexts/identity/handlers/send_welcome_email_on_registration.rb
module Identity
  module Handlers
    class SendWelcomeEmailOnRegistration
      def self.async? = true

      def self.call(event)
        UserMailer.welcome(event.user_id).deliver_later
      end
    end
  end
end
```

---

#### `Identity::UseCases::RequestPasswordReset`
```ruby
# app/contexts/identity/use_cases/request_password_reset.rb
module Identity
  module UseCases
    class RequestPasswordReset < ApplicationUseCase
      def call(params:)
        attrs = yield validate(Identity::Contracts::RequestPasswordResetContract, params)
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
end
```

#### `Identity::UseCases::ResetPassword`
```ruby
# app/contexts/identity/use_cases/reset_password.rb
module Identity
  module UseCases
    class ResetPassword < ApplicationUseCase
      def call(token:, params:)
        attrs = yield validate(Identity::Contracts::ResetPasswordContract, params)
        user  = yield find_by_token(token)
        _     = yield check_expiry(user)
        _     = yield update_password(user, attrs[:password])
        _     = yield publish(Events::PasswordChanged.new(user_id: user.id))

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
end
```

**Events:**
```ruby
# app/contexts/identity/events/password_changed.rb
module Identity
  module Events
    class PasswordChanged < BaseEvent
      attribute :user_id, Types::Integer
    end
  end
end
```

**Handler:**
```ruby
# app/contexts/identity/handlers/invalidate_sessions_on_password_change.rb
module Identity
  module Handlers
    class InvalidateSessionsOnPasswordChange
      def self.call(event)
        user = User.find(event.user_id)
        user.remember_tokens.destroy_all
      end
    end
  end
end
```

---

#### `Identity::UseCases::UpdateInfo`
```ruby
# app/contexts/identity/use_cases/update_info.rb
module Identity
  module UseCases
    class UpdateInfo < ApplicationUseCase
      def call(user:, params:)
        attrs = yield validate(Identity::Contracts::UpdateProfileContract, params)
        _     = yield persist(user, attrs)
        _     = yield publish(Events::ProfileUpdated.new(user_id: user.id))

      Success(user.reload)
    end

    private

      def persist(user, attrs)
        user.update(attrs) ? Success(user) : Failure([:persistence, user.errors.full_messages])
      end
    end
  end
end
```

#### `Identity::UseCases::ChangePassword`
```ruby
# app/contexts/identity/use_cases/change_password.rb
module Identity
  module UseCases
    class ChangePassword < ApplicationUseCase
      def call(user:, params:)
        attrs = yield validate(Identity::Contracts::ChangePasswordContract, params)
      _     = yield verify_current(user, attrs[:current_password])
      _     = yield persist(user, attrs[:password])
        _     = yield publish(Events::PasswordChanged.new(user_id: user.id))

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
end
```

---

### 4.2 Bounded Context: Trading (Portafolio, Posiciones, Watchlist)

> Watchlist se fusiono en este BC — es parte de la experiencia de trading del usuario.

#### `Trading::UseCases::AssembleDashboard`
```ruby
# app/contexts/trading/use_cases/assemble_dashboard.rb
module Trading
  module UseCases
    class AssembleDashboard < ApplicationUseCase
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
        Success(Domain::PortfolioSummary.new(portfolio, currency:).to_h)
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
        Success(MarketData::Domain::MarketSentiment.for_user(user))
      end
    end
  end
end
```

---

#### `Trading::UseCases::LoadPortfolio`
```ruby
# app/contexts/trading/use_cases/load_portfolio.rb
module Trading
  module UseCases
    class LoadPortfolio < ApplicationUseCase
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
        Success(Domain::PortfolioSummary.new(portfolio, currency:).to_h)
      end

      def build_allocation(portfolio)
        Success(portfolio.allocation_by_sector)
      end

      def load_dividends(portfolio)
        Success(portfolio.dividend_payments.includes(dividend: :asset).order(created_at: :desc))
      end
    end
  end
end
```

---

#### `Trading::UseCases::ExecuteTrade`
```ruby
# app/contexts/trading/use_cases/execute_trade.rb
module Trading
  module UseCases
    class ExecuteTrade < ApplicationUseCase
      def call(user:, params:)
        attrs     = yield validate(Trading::Contracts::ExecuteTradeContract, params)
      portfolio = yield load_portfolio(user)
      asset     = yield find_asset(attrs[:asset_symbol])
      trade     = yield persist_trade(portfolio, asset, attrs)
      position  = yield update_position(portfolio, asset, trade, attrs)
        _         = yield publish(Events::TradeExecuted.new(
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
# app/contexts/trading/contracts/execute_trade_contract.rb
module Trading
  module Contracts
    class ExecuteTradeContract < ApplicationContract
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
end
```

**Event:**
```ruby
# app/contexts/trading/events/trade_executed.rb
module Trading
  module Events
    class TradeExecuted < BaseEvent
  attribute :user_id,      Types::Integer
  attribute :trade_id,     Types::Integer
      attribute :asset_symbol, Types::String
      attribute :side,         Types::String
    end
  end
end
```

**Handlers:**
```ruby
# app/contexts/trading/handlers/recalculate_avg_cost_on_trade.rb
module Trading
  module Handlers
    class RecalculateAvgCostOnTrade
      def self.call(event)
        trade = Trade.find(event.trade_id)
        trade.position&.recalculate_avg_cost!
      end
    end
  end
end

# app/contexts/trading/handlers/log_trade_activity.rb
module Trading
  module Handlers
    class LogTradeActivity
      def self.call(event)
        AuditLog.create!(
          user_id: event.user_id,
          action: "trading.#{event.side}",
          changes: { asset: event.asset_symbol, trade_id: event.trade_id }
        )
      end
    end
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

#### `Trading::UseCases::AddToWatchlist`
```ruby
# app/contexts/trading/use_cases/add_to_watchlist.rb
module Trading
  module UseCases
    class AddToWatchlist < ApplicationUseCase
      def call(user:, asset_id:)
        asset = yield find_asset(asset_id)
        item  = yield persist(user, asset)
        _     = yield publish(Events::WatchlistItemAdded.new(user_id: user.id, asset_id: asset.id))

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

#### `Trading::UseCases::RemoveFromWatchlist`
```ruby
# app/contexts/trading/use_cases/remove_from_watchlist.rb
module Trading
  module UseCases
    class RemoveFromWatchlist < ApplicationUseCase
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

#### `Alerts::UseCases::CreateRule`
```ruby
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
```

**Contract:**
```ruby
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
```

#### `Alerts::UseCases::UpdateRule`
```ruby
# app/contexts/alerts/use_cases/update_rule.rb
module Alerts
  module UseCases
    class UpdateRule < ApplicationUseCase
      def call(user:, rule_id:, params:)
        attrs = yield validate(Alerts::Contracts::CreateContract, params)
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

#### `Alerts::UseCases::ToggleRule`
```ruby
# app/contexts/alerts/use_cases/toggle_rule.rb
module Alerts
  module UseCases
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

#### `Alerts::UseCases::DestroyRule`
```ruby
# app/contexts/alerts/use_cases/destroy_rule.rb
module Alerts
  module UseCases
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

#### `Alerts::UseCases::UpdatePreferences`
```ruby
# app/contexts/alerts/use_cases/update_preferences.rb
module Alerts
  module UseCases
    class UpdatePreferences < ApplicationUseCase
      def call(user:, params:)
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

#### `Alerts::UseCases::EvaluateRules`
```ruby
# app/contexts/alerts/use_cases/evaluate_rules.rb
module Alerts
  module UseCases
    class EvaluateRules < ApplicationUseCase
    def call(asset:, new_price:)
      rules     = yield load_active_rules(asset.symbol)
      triggered = yield evaluate(rules, asset, new_price)

      triggered.each do |rule|
        publish(Events::AlertRuleTriggered.new(
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

#### `MarketData::UseCases::ExploreAssets`
```ruby
# app/contexts/market_data/use_cases/explore_assets.rb
module MarketData
  module UseCases
    class ExploreAssets < ApplicationUseCase
      def call(params: {})
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

#### `MarketData::UseCases::ExportCsv`
```ruby
# app/contexts/market_data/use_cases/export_csv.rb (if applicable — currently in Administration)
module MarketData
  module UseCases
    class ExportCsv < ApplicationUseCase
      def call(user:, params: {})
        result = yield ExploreAssets.call(params:)
        csv    = yield generate(result[:assets])
        _      = yield publish(Administration::Events::CsvExported.new(user_id: user.id, export_type: "market_assets"))

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

#### `MarketData::UseCases::ListEarnings`
```ruby
# app/contexts/market_data/use_cases/list_earnings.rb
module MarketData
  module UseCases
    class ListEarnings < ApplicationUseCase
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

#### `Trading::UseCases::LoadAssetTrend`
```ruby
# app/contexts/trading/use_cases/load_asset_trend.rb
module Trading
  module UseCases
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

#### `Administration::UseCases::Assets::CreateAsset`
```ruby
# app/contexts/administration/use_cases/assets/create_asset.rb
module Administration
  module UseCases
    module Assets
      class CreateAsset < ApplicationUseCase
        def call(admin:, params:)
          attrs = yield validate(Administration::Contracts::Assets::CreateContract, params)
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

#### `Administration::UseCases::Assets::ToggleStatus`
```ruby
# app/contexts/administration/use_cases/assets/toggle_status.rb
module Administration
  module UseCases
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

#### `Administration::UseCases::Assets::TriggerSync`
```ruby
# app/contexts/administration/use_cases/assets/trigger_sync.rb
module Administration
  module UseCases
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

#### `Administration::UseCases::Users::SuspendUser`
```ruby
# app/contexts/administration/use_cases/users/suspend_user.rb
module Administration
  module UseCases
    module Users
      class SuspendUser < ApplicationUseCase
      def call(admin:, user_id:)
        user = yield find_user(user_id)
        _    = yield check_not_admin(user)
        _    = yield suspend(user)
        _    = yield audit(admin, user)
          _    = yield publish(Identity::Events::UserSuspended.new(user_id: user.id, email: user.email))

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

#### `Administration::UseCases::Integrations::ConnectProvider`
```ruby
# app/contexts/administration/use_cases/integrations/connect_provider.rb
module Administration
  module UseCases
    module Integrations
      class ConnectProvider < ApplicationUseCase
        def call(admin:, params:)
          attrs       = yield validate(Administration::Contracts::Integrations::ConnectContract, params)
        integration = yield persist(attrs)
        _           = yield audit(admin, integration)
          _           = yield publish(Events::IntegrationConnected.new(provider: integration.provider_name))

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

#### `Administration::UseCases::Integrations::RefreshSync`
```ruby
# app/contexts/administration/use_cases/integrations/refresh_sync.rb
module Administration
  module UseCases
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

#### `Administration::UseCases::Logs::ListLogs`
```ruby
# app/contexts/administration/use_cases/logs/list_logs.rb
module Administration
  module UseCases
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

#### `Notifications::UseCases::CreateNotification`
```ruby
# app/contexts/notifications/use_cases/create_notification.rb
module Notifications
  module UseCases
    class CreateNotification < ApplicationUseCase
      def call(user_id:, title:, body: nil, notification_type: :system, notifiable: nil)
        notification = yield persist(user_id, title, body, notification_type, notifiable)
        _            = yield publish(Events::NotificationCreated.new(user_id: user_id, notification_id: notification.id))

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

#### `Notifications::UseCases::MarkAsRead`
```ruby
# app/contexts/notifications/use_cases/mark_as_read.rb
module Notifications
  module UseCases
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

#### `MarketData::UseCases::ListArticles`
```ruby
# app/contexts/market_data/use_cases/list_articles.rb
module MarketData
  module UseCases
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

#### `Identity::UseCases::GlobalSearch`
```ruby
# app/contexts/identity/use_cases/global_search.rb
module Identity
  module UseCases
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

#### `Identity::UseCases::CompleteWizard`
```ruby
# app/contexts/identity/use_cases/complete_wizard.rb
module Identity
  module UseCases
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
# app/contexts/alerts/domain/alert_evaluator.rb
module Alerts
  module Domain
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
end
end
```

### 5.2 MarketSentiment

```ruby
# app/contexts/market_data/domain/market_sentiment.rb
module MarketData
  module Domain
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
end
end
```

### 5.3 PortfolioSummary

```ruby
# app/contexts/trading/domain/portfolio_summary.rb
module Trading
  module Domain
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
  # Identity
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::CreatePortfolioOnRegistration)
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::CreateAlertPreferencesOnRegistration)
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::SendWelcomeEmailOnRegistration)
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::SendVerificationEmailOnRegistration)
  EventBus.subscribe(Identity::Events::PasswordChanged, Identity::Handlers::InvalidateSessionsOnPasswordChange)
  EventBus.subscribe(Identity::Events::PasswordChanged, Identity::Handlers::CreateAuditLogOnPasswordChange)
  EventBus.subscribe(Identity::Events::UserLoggedIn, Identity::Handlers::CreateAuditLogOnLogin)
  EventBus.subscribe(Identity::Events::UserLoginFailed, Identity::Handlers::CreateAuditLogOnLoginFailure)

  # Administration
  EventBus.subscribe(Identity::Events::UserSuspended, Administration::Handlers::CreateAuditLogOnSuspension)
  EventBus.subscribe(Identity::Events::UserSuspended, Administration::Handlers::SendSuspensionEmail)
  EventBus.subscribe(MarketData::Events::AssetCreated, Administration::Handlers::CreateAuditLogOnAssetCreation)
  EventBus.subscribe(MarketData::Events::AssetCreated, MarketData::Handlers::SyncAssetOnCreation)
  EventBus.subscribe(MarketData::Events::AssetCreated, MarketData::Handlers::BackfillHistoryOnAssetCreation)

  # Market Data
  EventBus.subscribe(MarketData::Events::AssetPriceUpdated, Alerts::Handlers::EvaluateAlertsOnPriceUpdate)
  EventBus.subscribe(MarketData::Events::AssetPriceUpdated, MarketData::Handlers::BroadcastPriceUpdate)
  EventBus.subscribe(MarketData::Events::AssetPriceUpdated, MarketData::Handlers::RecordPriceHistory)
  EventBus.subscribe(MarketData::Events::AssetPriceUpdated, MarketData::Handlers::RecalculateTrendScoreOnPriceUpdate)
  EventBus.subscribe(MarketData::Events::AllGatewaysFailed, MarketData::Handlers::LogAllGatewaysFailure)
  EventBus.subscribe(MarketData::Events::FearGreedUpdated, Alerts::Handlers::EvaluateSentimentAlerts)

  # Alerts
  EventBus.subscribe(Alerts::Events::AlertRuleTriggered, Alerts::Handlers::CreateAlertEventOnTrigger)
  EventBus.subscribe(Alerts::Events::AlertRuleTriggered, Alerts::Handlers::CreateNotificationOnAlert)

  # Notifications
  EventBus.subscribe(Notifications::Events::NotificationCreated, Notifications::Handlers::BroadcastNotification)

  # Trading
  EventBus.subscribe(Trading::Events::TradeExecuted, Trading::Handlers::RecalculateAvgCostOnTrade)
  EventBus.subscribe(Trading::Events::TradeExecuted, Trading::Handlers::LogTradeActivity)
  EventBus.subscribe(Trading::Events::SplitDetected, Trading::Handlers::AdjustPositionsOnSplit)

  # ... plus additional logging handlers for News, Earnings, Indices, Dividends, CETES,
  #     Fundamentals, Integrations, and Pool Keys (see full file for details)
end
```

### Event: AssetPriceUpdated (el mas importante del sistema)

```ruby
# app/contexts/market_data/events/asset_price_updated.rb
module MarketData
  module Events
    class AssetPriceUpdated < BaseEvent
      attribute :asset_id,  Types::Integer
      attribute :symbol,    Types::String
      attribute :old_price, Types::String
      attribute :new_price, Types::String
    end
  end
end

# app/contexts/alerts/handlers/evaluate_alerts_on_price_update.rb
module Alerts
  module Handlers
    class EvaluateAlertsOnPriceUpdate
      def self.async? = true

      def self.call(event)
        asset = Asset.find(event.asset_id)
        Alerts::UseCases::EvaluateRules.call(asset: asset, new_price: BigDecimal(event.new_price))
      end
    end
  end
end

# app/contexts/market_data/handlers/broadcast_price_update.rb
module MarketData
  module Handlers
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
# app/contexts/alerts/events/alert_rule_triggered.rb
module Alerts
  module Events
    class AlertRuleTriggered < BaseEvent
  attribute :rule_id,      Types::Integer
  attribute :user_id,      Types::Integer
  attribute :asset_symbol, Types::String
      attribute :price,        Types::String
    end
  end
end

# app/contexts/alerts/handlers/create_alert_event_on_trigger.rb
module Alerts
  module Handlers
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
end
end

# app/contexts/alerts/handlers/create_notification_on_alert.rb
module Alerts
  module Handlers
    class CreateNotificationOnAlert
      def self.async? = true

      def self.call(event)
        user = User.find(event.user_id)
        Notifications::UseCases::CreateNotification.new.call(
      user: user,
      title: "#{event.asset_symbol} alert triggered",
      body: "Price reached $#{event.price}",
          notification_type: :alert_triggered
        )
      end
    end
  end
end

# app/contexts/notifications/handlers/broadcast_notification.rb
module Notifications
  module Handlers
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
| `SessionsController` | `create` | `Identity::UseCases::Login` | Redirect → dashboard |
| `SessionsController` | `destroy` | (inline logout) | Redirect → root |
| `RegistrationsController` | `create` | `Identity::UseCases::Register` | Redirect → dashboard |
| `PasswordResetsController` | `create` | `Identity::UseCases::RequestPasswordReset` | Flash + redirect |
| `PasswordResetsController` | `update` | `Identity::UseCases::ResetPassword` | Redirect → login |
| `DashboardController` | `show` | `Trading::UseCases::AssembleDashboard` | Full page |
| `MarketController` | `index` | `MarketData::UseCases::ExploreAssets` | Turbo Frame `market_listings` |
| `PortfolioController` | `show` | `Trading::UseCases::LoadPortfolio` | Turbo Frame `positions_tab` |
| `AlertsController` | `index` | `Alerts::UseCases::LoadDashboard` | Full page |
| `AlertsController` | `create` | `Alerts::UseCases::CreateRule` | Turbo Stream prepend |
| `AlertsController` | `update` | `Alerts::UseCases::UpdateRule` | Turbo Stream replace |
| `AlertsController` | `toggle` | `Alerts::UseCases::ToggleRule` | Turbo Stream replace |
| `AlertsController` | `destroy` | `Alerts::UseCases::DestroyRule` | Turbo Stream remove |
| `EarningsController` | `index` | `MarketData::UseCases::ListEarnings` | Turbo Frame `calendar_grid` |
| `ProfileController` | `show` | `Identity::UseCases::LoadProfile` | Full page |
| `ProfileController` | `update` | `Identity::UseCases::UpdateInfo` | Turbo Stream replace |
| `WatchlistItemsController` | `create` | `Trading::UseCases::AddToWatchlist` | Turbo Stream append |
| `WatchlistItemsController` | `destroy` | `Trading::UseCases::RemoveFromWatchlist` | Turbo Stream remove |
| `TrendsController` | `index` | `Trading::UseCases::LoadAssetTrend` | Turbo Frame |
| `NotificationsController` | `index` | `Notifications::UseCases::ListRecent` | Turbo Frame dropdown |
| `NotificationsController` | `update` | `Notifications::UseCases::MarkAsRead` | Turbo Stream replace |
| `NewsController` | `index` | `MarketData::UseCases::ListArticles` | Turbo Frame |
| `SearchController` | `index` | `Identity::UseCases::GlobalSearch` | Turbo Frame |
| `OnboardingController` | `update` | `Identity::UseCases::CompleteWizard` | Redirect → dashboard |
| `Admin::AssetsController` | `index` | `Administration::UseCases::Assets::ListAssets` | Full page |
| `Admin::AssetsController` | `create` | `Administration::UseCases::Assets::CreateAsset` | Turbo Stream prepend |
| `Admin::AssetsController` | `toggle` | `Administration::UseCases::Assets::ToggleStatus` | Turbo Stream replace |
| `Admin::AssetsController` | `sync` | `Administration::UseCases::Assets::TriggerSync` | Flash notice |
| `Admin::UsersController` | `index` | `Administration::UseCases::Users::ListUsers` | Full page |
| `Admin::UsersController` | `suspend` | `Administration::UseCases::Users::SuspendUser` | Turbo Stream replace |
| `Admin::LogsController` | `index` | `Administration::UseCases::Logs::ListLogs` | Turbo Frame `logs_table` |
| `Admin::IntegrationsController` | `create` | `Administration::UseCases::Integrations::ConnectProvider` | Redirect |
| `Admin::DashboardController` | `show` | `Administration::UseCases::Dashboard::LoadSyncOverview` | Full page |

---

## 8. Gateways (Output Ports para APIs externas)

```ruby
# app/contexts/market_data/gateways/market_data_gateway.rb (Interface / Port)
module MarketData
  module Gateways
    class MarketDataGateway
  def fetch_price(symbol)
    raise NotImplementedError
  end

      def fetch_bulk_prices(symbols)
        raise NotImplementedError
      end
    end
  end
end

# app/contexts/market_data/gateways/polygon_gateway.rb (Adapter)
module MarketData
  module Gateways
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
  end
end

# app/contexts/market_data/gateways/coingecko_gateway.rb (Adapter)
module MarketData
  module Gateways
    class CoingeckoGateway < MarketDataGateway
  def fetch_price(symbol)
    Success({ symbol:, price: 64231.00, change: 0.85 })
  rescue => e
    Failure([:gateway_error, e.message])
  end

      include Dry::Monads[:result]
    end
  end
end

# app/contexts/market_data/gateways/fx_rates_gateway.rb (Adapter)
module MarketData
  module Gateways
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
| **Identity** | `Login`, `Register`, `RequestPasswordReset`, `ResetPassword`, `UpdateInfo`, `ChangePassword`, `VerifyEmail`, `CompleteWizard`, `GlobalSearch`, `LoadProfile`, `LoadProgress`, `LoadAssetCatalog` | `UserRegistered`, `PasswordChanged`, `ProfileUpdated`, `EmailVerified`, `UserLoggedIn`, `UserLoginFailed`, `UserSuspended` | User, AlertPreference, RememberToken |
| **Trading** | `AssembleDashboard`, `LoadPortfolio`, `ExecuteTrade`, `UpdateTrade`, `DeleteTrade`, `AddToWatchlist`, `RemoveFromWatchlist`, `LoadAssetTrend` | `TradeExecuted`, `TradeUpdated`, `TradeDeleted`, `PositionOpened`, `PositionClosed`, `WatchlistItemAdded`, `PortfolioSnapshotTaken`, `SplitDetected` | Portfolio, Position, Trade, WatchlistItem, PortfolioSnapshot, DividendPayment |
| **Alerts** | `CreateRule`, `UpdateRule`, `ToggleRule`, `DestroyRule`, `UpdatePreferences`, `EvaluateRules`, `EvaluateSentimentRules`, `LoadDashboard` | `AlertRuleCreated`, `AlertRuleTriggered` | AlertRule, AlertEvent |
| **Market Data** | `ExploreAssets`, `ListEarnings`, `ListArticles`, `LoadAssetDetail`, `SyncArticles`, `SyncEarnings`, `SyncCetes`, `SyncCryptoFundamentals`, `NotifyApproachingEarnings` | `AssetPriceUpdated`, `AssetCreated`, `AssetDeleted`, `NewsSynced`, `EarningsSynced`, `FearGreedUpdated`, `MarketIndicesUpdated`, `DividendsSynced`, `CetesSynced`, `AssetFundamentalsUpdated`, `FinancialStatementsSynced`, `FxRatesRefreshed`, `AllGatewaysFailed` | Asset, TrendScore, EarningsEvent, MarketIndex, NewsArticle, AssetPriceHistory, FxRate, Dividend |
| **Administration** | `Assets::CreateAsset`, `Assets::DeleteAsset`, `Assets::ListAssets`, `Assets::ToggleStatus`, `Assets::TriggerSync`, `Users::SuspendUser`, `Users::ListUsers`, `Integrations::ConnectProvider`, `Integrations::UpdateProvider`, `Integrations::DeleteProvider`, `Integrations::RefreshSync`, `Integrations::AddPoolKey`, `Integrations::TogglePoolKey`, `Integrations::RemovePoolKey`, `Logs::ListLogs`, `Logs::ExportCsv`, `Dashboard::LoadSyncOverview` | `CsvExported`, `IntegrationConnected`, `IntegrationUpdated`, `IntegrationDeleted`, `PoolKeyAdded`, `PoolKeyToggled`, `PoolKeyRemoved` | SystemLog, Integration, AuditLog |
| **Notifications** | `CreateNotification`, `ListRecent`, `MarkAsRead` | `NotificationCreated` | Notification |
