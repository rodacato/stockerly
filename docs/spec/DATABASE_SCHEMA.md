# Stockerly - Modelado de Base de Datos

> Esquema completo de PostgreSQL para Stockerly.
> Incluye migraciones, asociaciones, enums, indices, validaciones y seeds.
>
> **Nota:** Este es el documento fuente de verdad para el schema de BD.
> Usa la gem `money-rails` para manejo de divisas y conversion FX.

---

## 1. Diagrama de Relaciones (ERD)

```
                                    ┌──────────────────┐
                                    │   MarketIndex     │
                                    │──────────────────│
                                    │ name             │
                                    │ symbol           │
                                    │ value            │
                                    │ change_percent   │
                                    │ exchange         │
                                    │ is_open          │
                                    └──────────────────┘

┌──────────────────┐     1    ┌──────────────────┐    1     ┌──────────────────┐
│   User           │─────────│   Portfolio       │─────────│ AlertPreference   │
│──────────────────│         │──────────────────│          │──────────────────│
│ full_name        │         │ buying_power     │          │ browser_push     │
│ email            │         │ inception_date   │          │ email_digest     │
│ password_digest  │         └────────┬─────────┘          │ sms_notifications│
│ role             │                  │ *                   └──────────────────┘
│ status           │         ┌────────┴─────────┐
│ preferred_currency│        │   Position        │    ┌──────────────────┐
└──┬───┬───────────┘         │──────────────────│    │   Trade           │
   │   │                     │ shares           │    │──────────────────│
   │   │ *                   │ avg_cost         │    │ side (buy/sell)  │
   │   ├─────────────┐       │ currency         │    │ shares           │
   │   │             │       │ status           │    │ price_per_share  │
   │   │             │       └────────┬─────────┘    │ fee              │
   │   │             │                │              │ executed_at      │
   │   │             │                │ 1            └──────────────────┘
   │ ┌─┴──────────┐  │       ┌────────┴─────────┐
   │ │WatchlistItem│  │       │   Asset           │
   │ │────────────│  │       │──────────────────│
   │ │ entry_price│  │       │ name             │──── AssetPriceHistory *
   │ │ created_at │──┼──────│ symbol           │
   │ └────────────┘  │       │ asset_type       │──── TrendScore *
   │                 │       │ sector           │
   │ *               │       │ exchange         │──── EarningsEvent *
   ├─────────────┐   │       │ current_price    │
   │             │   │       │ price_updated_at │──── Dividend *
   │ Notification│   │       └──────────────────┘
   │ (poly)      │   │
   │             │   │       ┌──────────────────┐
┌──┴──────────┐  │   │       │ PortfolioSnapshot │
│ AlertRule    │  │   │       │──────────────────│
│────────────│  │   │       │ date             │
│ asset_symbol│  │   │       │ total_value      │
│ condition   │  │   │       └──────────────────┘
│ threshold   │  │   │
│ status      │  │   │       ┌──────────────────┐
└──┬──────────┘  │   │       │  FxRate           │
   │ *           │   │       │──────────────────│
┌──┴──────────┐  │   │       │ base_currency    │
│ AlertEvent  │  │   │       │ quote_currency   │
│────────────│  │   │       │ rate             │
│ user_id     │  │   │       └──────────────────┘
│ asset_symbol│  │   │
│ message     │  │   │       ┌──────────────────┐
│ event_status│  │   │       │  NewsArticle      │
│ triggered_at│  │   │       │──────────────────│
└─────────────┘  │   │       │ title            │
                 │   │       │ source           │
                 │   │       │ related_ticker   │
 RememberToken * │   │       │ url              │
                 │   │       └──────────────────┘
                 │   │
                 │   │       ┌──────────────────┐    ┌──────────────────┐
                 │   │       │  SystemLog        │    │  Integration     │
                 │   │       │──────────────────│    │──────────────────│
                 │   │       │ task_name        │    │ provider_name    │
                 │   │       │ module_name      │    │ api_key_encrypted│
                 │   │       │ severity         │    │ connection_status│
                 │   │       └──────────────────┘    └──────────────────┘
                 │   │
                 │   │       ┌──────────────────┐
                 │   │       │  AuditLog         │
                 │   │       │──────────────────│
                 │   │       │ user_id (actor)  │
                 │   │       │ action           │
                 │   │       │ auditable (poly) │
                 │   │       │ changes (jsonb)  │
                 │   │       └──────────────────┘
```

---

## 2. Migraciones

### 2.1 Users

```ruby
# db/migrate/001_create_users.rb
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string  :full_name,           null: false
      t.string  :email,               null: false
      t.string  :password_digest,     null: false
      t.string  :avatar_url
      t.integer :role,                null: false, default: 0  # enum: user=0, admin=1
      t.integer :status,              null: false, default: 0  # enum: active=0, suspended=1
      t.boolean :is_verified,         null: false, default: false
      t.string  :preferred_currency,  null: false, default: "USD"
      t.string  :password_reset_token
      t.datetime :password_reset_sent_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
    add_index :users, :status
    add_index :users, :password_reset_token, unique: true
  end
end
```

### 2.2 Assets

```ruby
# db/migrate/002_create_assets.rb
class CreateAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :assets do |t|
      t.string  :name,               null: false
      t.string  :symbol,             null: false
      t.integer :asset_type,         null: false, default: 0  # stock=0, crypto=1, index=2
      t.string  :sector
      t.string  :exchange
      t.string  :data_source                                   # "Polygon.io", "CoinGecko API"
      t.integer :sync_status,        null: false, default: 0  # active=0, disabled=1, sync_issue=2
      t.decimal :current_price,      precision: 15, scale: 4
      t.decimal :change_percent_24h, precision: 8,  scale: 4
      t.decimal :market_cap,         precision: 20, scale: 2
      t.decimal :pe_ratio,           precision: 10, scale: 4
      t.decimal :div_yield,          precision: 8,  scale: 4
      t.bigint  :volume
      t.bigint  :shares_outstanding
      t.datetime :price_updated_at                              # Frescura del dato de precio

      t.timestamps
    end

    add_index :assets, :symbol, unique: true
    add_index :assets, :asset_type
    add_index :assets, :sector
    add_index :assets, :exchange
    add_index :assets, :sync_status
    add_index :assets, [:asset_type, :sector]
  end
end
```

### 2.3 Portfolios

```ruby
# db/migrate/003_create_portfolios.rb
class CreatePortfolios < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolios do |t|
      t.references :user,           null: false, foreign_key: true, index: { unique: true }
      t.decimal    :buying_power,   precision: 15, scale: 2, null: false, default: 0
      t.date       :inception_date

      t.timestamps
    end
  end
end
```

### 2.4 Positions

```ruby
# db/migrate/004_create_positions.rb
class CreatePositions < ActiveRecord::Migration[8.1]
  def change
    create_table :positions do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :asset,     null: false, foreign_key: true
      t.decimal    :shares,    precision: 15, scale: 6, null: false
      t.decimal    :avg_cost,  precision: 15, scale: 4, null: false  # Cached, recalculado desde Trades
      t.string     :currency,  null: false, default: "USD"
      t.integer    :status,    null: false, default: 0  # open=0, closed=1
      t.datetime   :opened_at
      t.datetime   :closed_at

      t.timestamps
    end

    add_index :positions, :status
    add_index :positions, [:portfolio_id, :asset_id, :status]
  end
end
```

### 2.5 Trades

```ruby
# db/migrate/005_create_trades.rb
class CreateTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :trades do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :asset,     null: false, foreign_key: true
      t.references :position,  foreign_key: true  # nullable para trades sin posicion abierta
      t.integer    :side,            null: false   # buy=0, sell=1
      t.decimal    :shares,          precision: 15, scale: 6, null: false
      t.decimal    :price_per_share, precision: 15, scale: 4, null: false
      t.decimal    :total_amount,    precision: 15, scale: 2, null: false
      t.decimal    :fee,             precision: 10, scale: 2, default: 0
      t.string     :currency,        null: false, default: "USD"
      t.datetime   :executed_at,     null: false

      t.timestamps
    end

    add_index :trades, [:portfolio_id, :asset_id]
    add_index :trades, :executed_at
    add_index :trades, :side
  end
end
```

### 2.6 Watchlist Items

```ruby
# db/migrate/006_create_watchlist_items.rb
class CreateWatchlistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :watchlist_items do |t|
      t.references :user,  null: false, foreign_key: true
      t.references :asset, null: false, foreign_key: true
      t.decimal    :entry_price, precision: 15, scale: 4  # Precio al momento de agregar

      t.timestamps
    end

    add_index :watchlist_items, [:user_id, :asset_id], unique: true
  end
end
```

### 2.7 Alert Rules

```ruby
# db/migrate/007_create_alert_rules.rb
class CreateAlertRules < ActiveRecord::Migration[8.1]
  def change
    create_table :alert_rules do |t|
      t.references :user,         null: false, foreign_key: true
      t.string     :asset_symbol, null: false
      t.integer    :condition,    null: false
      # conditions: price_crosses_above=0, price_crosses_below=1,
      #             day_change_percent=2, rsi_overbought=3, rsi_oversold=4
      t.decimal    :threshold_value, precision: 15, scale: 4, null: false
      t.integer    :status,       null: false, default: 0  # active=0, paused=1

      t.timestamps
    end

    add_index :alert_rules, [:user_id, :status]
    add_index :alert_rules, :asset_symbol
  end
end
```

### 2.8 Alert Events

```ruby
# db/migrate/008_create_alert_events.rb
class CreateAlertEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :alert_events do |t|
      t.references :alert_rule,   foreign_key: true  # nullable (events can outlive rules)
      t.references :user,         null: false, foreign_key: true
      t.string     :asset_symbol, null: false
      t.string     :message,      null: false
      t.integer    :event_status, null: false, default: 0  # triggered=0, settled=1
      t.datetime   :triggered_at, null: false

      t.timestamps
    end

    add_index :alert_events, [:user_id, :triggered_at]
    add_index :alert_events, :event_status
  end
end
```

### 2.9 Alert Preferences

```ruby
# db/migrate/009_create_alert_preferences.rb
class CreateAlertPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :alert_preferences do |t|
      t.references :user,              null: false, foreign_key: true, index: { unique: true }
      t.boolean    :browser_push,      null: false, default: true
      t.boolean    :email_digest,      null: false, default: true
      t.boolean    :sms_notifications, null: false, default: false

      t.timestamps
    end
  end
end
```

### 2.10 Earnings Events

```ruby
# db/migrate/010_create_earnings_events.rb
class CreateEarningsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :earnings_events do |t|
      t.references :asset,         null: false, foreign_key: true
      t.date       :report_date,   null: false
      t.integer    :timing,        null: false  # before_market_open=0, after_market_close=1
      t.decimal    :estimated_eps, precision: 10, scale: 4
      t.decimal    :actual_eps,    precision: 10, scale: 4

      t.timestamps
    end

    add_index :earnings_events, :report_date
    add_index :earnings_events, [:asset_id, :report_date], unique: true
  end
end
```

### 2.11 News Articles

```ruby
# db/migrate/011_create_news_articles.rb
class CreateNewsArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :news_articles do |t|
      t.string   :title,          null: false
      t.text     :summary
      t.string   :image_url
      t.string   :source,         null: false  # "Bloomberg", "Reuters", "WSJ"
      t.string   :related_ticker
      t.string   :url
      t.datetime :published_at,   null: false

      t.timestamps
    end

    add_index :news_articles, :published_at
    add_index :news_articles, :related_ticker
  end
end
```

### 2.12 Market Indices

```ruby
# db/migrate/012_create_market_indices.rb
class CreateMarketIndices < ActiveRecord::Migration[8.1]
  def change
    create_table :market_indices do |t|
      t.string  :name,            null: false
      t.string  :symbol,          null: false
      t.decimal :value,           precision: 15, scale: 4
      t.decimal :change_percent,  precision: 8,  scale: 4
      t.string  :exchange
      t.boolean :is_open,         null: false, default: false

      t.timestamps
    end

    add_index :market_indices, :symbol, unique: true
  end
end
```

### 2.13 Trend Scores

```ruby
# db/migrate/013_create_trend_scores.rb
class CreateTrendScores < ActiveRecord::Migration[8.1]
  def change
    create_table :trend_scores do |t|
      t.references :asset,        null: false, foreign_key: true
      t.integer    :score,        null: false  # 0-100
      t.integer    :label,        null: false  # weak=0, moderate=1, strong=2, parabolic=3, sideways=4, weakening=5
      t.integer    :direction,    null: false  # upward=0, downward=1
      t.datetime   :calculated_at, null: false

      t.timestamps
    end

    add_index :trend_scores, [:asset_id, :calculated_at]
    add_index :trend_scores, :score
  end
end
```

### 2.14 System Logs

```ruby
# db/migrate/014_create_system_logs.rb
class CreateSystemLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :system_logs do |t|
      t.string  :task_name,        null: false
      t.string  :module_name,      null: false  # "Finance", "Marketplace", "Auth", "Core"
      t.integer :severity,         null: false  # success=0, error=1, warning=2
      t.decimal :duration_seconds, precision: 10, scale: 3
      t.text    :error_message
      t.string  :log_uid                         # External log ID

      t.timestamps
    end

    add_index :system_logs, :severity
    add_index :system_logs, :module_name
    add_index :system_logs, :created_at
    add_index :system_logs, [:severity, :created_at]
  end
end
```

### 2.15 Integrations

```ruby
# db/migrate/015_create_integrations.rb
class CreateIntegrations < ActiveRecord::Migration[8.1]
  def change
    create_table :integrations do |t|
      t.string  :provider_name,      null: false  # "Polygon.io", "CoinGecko"
      t.string  :provider_type,      null: false  # "Stocks & Forex", "Cryptocurrency"
      t.string  :api_key_encrypted
      t.integer :connection_status,  null: false, default: 0  # connected=0, syncing=1, disconnected=2
      t.datetime :last_sync_at

      t.timestamps
    end

    add_index :integrations, :provider_name, unique: true
    add_index :integrations, :connection_status
  end
end
```

### 2.16 Portfolio Snapshots

```ruby
# db/migrate/016_create_portfolio_snapshots.rb
class CreatePortfolioSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolio_snapshots do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.date       :date,           null: false
      t.decimal    :total_value,    precision: 15, scale: 2, null: false
      t.decimal    :cash_value,     precision: 15, scale: 2, null: false
      t.decimal    :invested_value, precision: 15, scale: 2, null: false

      t.timestamps
    end

    add_index :portfolio_snapshots, [:portfolio_id, :date], unique: true
    add_index :portfolio_snapshots, :date
  end
end
```

### 2.17 FX Rates

```ruby
# db/migrate/017_create_fx_rates.rb
class CreateFxRates < ActiveRecord::Migration[8.1]
  def change
    create_table :fx_rates do |t|
      t.string   :base_currency,  null: false  # "USD"
      t.string   :quote_currency, null: false  # "MXN"
      t.decimal  :rate,           precision: 15, scale: 6, null: false  # 17.25
      t.datetime :fetched_at,     null: false

      t.timestamps
    end

    add_index :fx_rates, [:base_currency, :quote_currency], unique: true
    add_index :fx_rates, :fetched_at
  end
end
```

### 2.18 Asset Price History

```ruby
# db/migrate/018_create_asset_price_histories.rb
class CreateAssetPriceHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_price_histories do |t|
      t.references :asset, null: false, foreign_key: true
      t.date       :date,    null: false
      t.decimal    :open,    precision: 15, scale: 4
      t.decimal    :high,    precision: 15, scale: 4
      t.decimal    :low,     precision: 15, scale: 4
      t.decimal    :close,   precision: 15, scale: 4, null: false
      t.bigint     :volume

      t.timestamps
    end

    add_index :asset_price_histories, [:asset_id, :date], unique: true
    add_index :asset_price_histories, :date
  end
end
```

### 2.19 Notifications

```ruby
# db/migrate/019_create_notifications.rb
class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user,       null: false, foreign_key: true
      t.string     :title,      null: false
      t.text       :body
      t.integer    :notification_type, null: false, default: 0
      # alert_triggered=0, earnings_reminder=1, system=2
      t.boolean    :read,       null: false, default: false
      t.references :notifiable, polymorphic: true  # AlertEvent, EarningsEvent, etc.

      t.timestamps
    end

    add_index :notifications, [:user_id, :read]
    add_index :notifications, [:user_id, :created_at]
  end
end
```

### 2.20 Audit Logs

```ruby
# db/migrate/020_create_audit_logs.rb
class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user,      null: false, foreign_key: true  # Quien ejecuto la accion
      t.string     :action,    null: false  # "admin.users.suspend", "admin.assets.toggle_status"
      t.references :auditable, polymorphic: true  # User, Asset, Integration, etc.
      t.jsonb      :changes,   default: {}  # { before: {}, after: {} }
      t.string     :ip_address

      t.timestamps
    end

    add_index :audit_logs, [:user_id, :created_at]
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
```

### 2.21 Dividends

```ruby
# db/migrate/021_create_dividends.rb
class CreateDividends < ActiveRecord::Migration[8.1]
  def change
    create_table :dividends do |t|
      t.references :asset,            null: false, foreign_key: true
      t.date       :ex_date,          null: false
      t.date       :pay_date
      t.decimal    :amount_per_share, precision: 10, scale: 4, null: false
      t.string     :currency,         null: false, default: "USD"

      t.timestamps
    end

    add_index :dividends, [:asset_id, :ex_date], unique: true
    add_index :dividends, :ex_date
  end
end
```

### 2.22 Dividend Payments

```ruby
# db/migrate/022_create_dividend_payments.rb
class CreateDividendPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :dividend_payments do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :dividend,  null: false, foreign_key: true
      t.decimal    :shares_held,   precision: 15, scale: 6, null: false
      t.decimal    :total_amount,  precision: 15, scale: 2, null: false
      t.datetime   :received_at

      t.timestamps
    end

    add_index :dividend_payments, [:portfolio_id, :dividend_id], unique: true
  end
end
```

### 2.23 Remember Tokens

```ruby
# db/migrate/023_create_remember_tokens.rb
class CreateRememberTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :remember_tokens do |t|
      t.references :user,         null: false, foreign_key: true
      t.string     :token_digest, null: false
      t.datetime   :expires_at,   null: false
      t.datetime   :last_used_at
      t.string     :ip_address
      t.string     :user_agent

      t.timestamps
    end

    add_index :remember_tokens, :token_digest, unique: true
    add_index :remember_tokens, [:user_id, :expires_at]
  end
end
```

---

## 3. Modelos Rails

### 3.1 User

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # --- Enums ---
  enum :role,   { user: 0, admin: 1 }
  enum :status, { active: 0, suspended: 1 }

  # --- Asociaciones ---
  has_one  :portfolio,        dependent: :destroy
  has_one  :alert_preference, dependent: :destroy
  has_many :watchlist_items,  dependent: :destroy
  has_many :watched_assets,   through: :watchlist_items, source: :asset
  has_many :alert_rules,      dependent: :destroy
  has_many :alert_events,     dependent: :destroy
  has_many :notifications,    dependent: :destroy
  has_many :remember_tokens,  dependent: :destroy
  has_many :audit_logs

  # --- Validaciones ---
  validates :full_name, presence: true
  validates :email,     presence: true, uniqueness: { case_sensitive: false },
                        format: { with: URI::MailTo::EMAIL_REGEXP }

  # --- Scopes ---
  scope :admins,        -> { where(role: :admin) }
  scope :traders,       -> { where(role: :user) }
  scope :not_suspended, -> { where.not(status: :suspended) }

  # NOTA: Portfolio y AlertPreference se crean via event handlers
  # del evento UserRegistered (ver COMMANDS.md), NO via callbacks.
end
```

### 3.2 Asset

```ruby
# app/models/asset.rb
class Asset < ApplicationRecord
  enum :asset_type,  { stock: 0, crypto: 1, index: 2 }
  enum :sync_status, { active: 0, disabled: 1, sync_issue: 2 }

  has_many :positions
  has_many :trades
  has_many :watchlist_items,       dependent: :destroy
  has_many :watching_users,        through: :watchlist_items, source: :user
  has_many :trend_scores,          dependent: :destroy
  has_many :earnings_events,       dependent: :destroy
  has_many :asset_price_histories, dependent: :destroy
  has_many :dividends,             dependent: :destroy

  validates :name,   presence: true
  validates :symbol, presence: true, uniqueness: { case_sensitive: false }

  scope :stocks,    -> { where(asset_type: :stock) }
  scope :cryptos,   -> { where(asset_type: :crypto) }
  scope :syncing,   -> { where(sync_status: :active) }
  scope :by_sector, ->(sector) { where(sector: sector) if sector.present? }

  def latest_trend_score
    trend_scores.order(calculated_at: :desc).first
  end

  def price_stale?
    price_updated_at.nil? || price_updated_at < 15.minutes.ago
  end
end
```

### 3.3 Portfolio

```ruby
# app/models/portfolio.rb
class Portfolio < ApplicationRecord
  belongs_to :user
  has_many   :positions,          dependent: :destroy
  has_many   :trades,             dependent: :destroy
  has_many   :assets,             through: :positions
  has_many   :snapshots,          class_name: "PortfolioSnapshot", dependent: :destroy
  has_many   :dividend_payments,  dependent: :destroy

  def open_positions
    positions.where(status: :open)
  end

  def closed_positions
    positions.where(status: :closed)
  end

  def total_value
    open_positions.sum { |p| p.shares * (p.asset.current_price || 0) } + buying_power
  end

  def total_unrealized_gain
    open_positions.sum { |p| p.shares * ((p.asset.current_price || 0) - p.avg_cost) }
  end

  def allocation_by_sector
    open_positions
      .joins(:asset)
      .group("assets.sector")
      .sum("positions.shares * assets.current_price")
  end

  def yesterday_snapshot
    snapshots.where(date: Date.yesterday).first
  end
end
```

### 3.4 Position

```ruby
# app/models/position.rb
class Position < ApplicationRecord
  belongs_to :portfolio
  belongs_to :asset
  has_many   :trades

  enum :status, { open: 0, closed: 1 }

  validates :shares,   presence: true, numericality: { greater_than: 0 }
  validates :avg_cost, presence: true, numericality: { greater_than: 0 }

  scope :domestic,      -> { where(currency: "USD") }
  scope :international, -> { where.not(currency: "USD") }

  def market_value
    shares * (asset.current_price || 0)
  end

  def total_gain
    shares * ((asset.current_price || 0) - avg_cost)
  end

  def total_gain_percent
    return 0 if avg_cost.zero?
    ((asset.current_price || 0) - avg_cost) / avg_cost * 100
  end

  # Recalcula avg_cost desde buy trades abiertos
  def recalculate_avg_cost!
    buy_trades = trades.where(side: :buy)
    return if buy_trades.empty?

    total_shares = buy_trades.sum(:shares)
    weighted_cost = buy_trades.sum("shares * price_per_share")
    update!(avg_cost: weighted_cost / total_shares)
  end
end
```

### 3.5 Trade

```ruby
# app/models/trade.rb
class Trade < ApplicationRecord
  belongs_to :portfolio
  belongs_to :asset
  belongs_to :position, optional: true

  enum :side, { buy: 0, sell: 1 }

  validates :shares,          presence: true, numericality: { greater_than: 0 }
  validates :price_per_share, presence: true, numericality: { greater_than: 0 }
  validates :total_amount,    presence: true
  validates :executed_at,     presence: true

  before_validation :calculate_total_amount, on: :create

  scope :buys,  -> { where(side: :buy) }
  scope :sells, -> { where(side: :sell) }
  scope :recent, -> { order(executed_at: :desc) }

  private

  def calculate_total_amount
    self.total_amount = (shares || 0) * (price_per_share || 0)
  end
end
```

### 3.6 WatchlistItem

```ruby
# app/models/watchlist_item.rb
class WatchlistItem < ApplicationRecord
  belongs_to :user
  belongs_to :asset

  validates :asset_id, uniqueness: { scope: :user_id, message: "already in watchlist" }

  # entry_price se captura automaticamente al agregar a watchlist
  before_create :capture_entry_price

  private

  def capture_entry_price
    self.entry_price ||= asset.current_price
  end
end
```

### 3.7 AlertRule

```ruby
# app/models/alert_rule.rb
class AlertRule < ApplicationRecord
  belongs_to :user
  has_many   :alert_events, dependent: :nullify

  enum :condition, {
    price_crosses_above: 0,
    price_crosses_below: 1,
    day_change_percent:  2,
    rsi_overbought:      3,
    rsi_oversold:        4
  }
  enum :status, { active: 0, paused: 1 }

  validates :asset_symbol,    presence: true
  validates :threshold_value, presence: true, numericality: true
end
```

### 3.8 AlertEvent

```ruby
# app/models/alert_event.rb
class AlertEvent < ApplicationRecord
  belongs_to :alert_rule, optional: true
  belongs_to :user

  enum :event_status, { triggered: 0, settled: 1 }

  validates :asset_symbol, presence: true
  validates :message,      presence: true
  validates :triggered_at, presence: true

  scope :recent, -> { order(triggered_at: :desc).limit(10) }
end
```

### 3.9 AlertPreference

```ruby
# app/models/alert_preference.rb
class AlertPreference < ApplicationRecord
  belongs_to :user
end
```

### 3.10 EarningsEvent

```ruby
# app/models/earnings_event.rb
class EarningsEvent < ApplicationRecord
  belongs_to :asset

  enum :timing, { before_market_open: 0, after_market_close: 1 }

  validates :report_date, presence: true, uniqueness: { scope: :asset_id }
  validates :timing,      presence: true

  scope :for_month, ->(date) {
    where(report_date: date.beginning_of_month..date.end_of_month)
  }
  scope :upcoming, -> { where("report_date >= ?", Date.current).order(:report_date) }
end
```

### 3.11 NewsArticle

```ruby
# app/models/news_article.rb
class NewsArticle < ApplicationRecord
  validates :title,        presence: true
  validates :source,       presence: true
  validates :published_at, presence: true

  scope :recent, -> { order(published_at: :desc).limit(10) }
  scope :for_ticker, ->(ticker) { where(related_ticker: ticker) if ticker.present? }
end
```

### 3.12 MarketIndex

```ruby
# app/models/market_index.rb
class MarketIndex < ApplicationRecord
  validates :name,   presence: true
  validates :symbol, presence: true, uniqueness: true

  scope :major, -> { where(symbol: %w[SPX NDX DJI UKX]) }
end
```

### 3.13 TrendScore

```ruby
# app/models/trend_score.rb
class TrendScore < ApplicationRecord
  belongs_to :asset

  enum :label, {
    weak: 0, moderate: 1, strong: 2,
    parabolic: 3, sideways: 4, weakening: 5
  }
  enum :direction, { upward: 0, downward: 1 }

  validates :score, presence: true, inclusion: { in: 0..100 }

  scope :latest, -> { order(calculated_at: :desc) }
end
```

### 3.14 SystemLog

```ruby
# app/models/system_log.rb
# Para operaciones tecnicas del sistema (sync, backup, cleanup)
class SystemLog < ApplicationRecord
  enum :severity, { success: 0, error: 1, warning: 2 }

  validates :task_name,   presence: true
  validates :module_name, presence: true

  scope :recent,     -> { order(created_at: :desc) }
  scope :errors,     -> { where(severity: :error) }
  scope :last_24h,   -> { where("created_at >= ?", 24.hours.ago) }
  scope :by_module,  ->(mod) { where(module_name: mod) if mod.present? }
end
```

### 3.15 Integration

```ruby
# app/models/integration.rb
class Integration < ApplicationRecord
  enum :connection_status, { connected: 0, syncing: 1, disconnected: 2 }

  validates :provider_name, presence: true, uniqueness: true
  validates :provider_type, presence: true

  encrypts :api_key_encrypted  # Rails 8 built-in encryption

  def masked_api_key
    return nil unless api_key_encrypted.present?
    "••••••••••••#{api_key_encrypted.last(4)}"
  end
end
```

### 3.16 PortfolioSnapshot

```ruby
# app/models/portfolio_snapshot.rb
class PortfolioSnapshot < ApplicationRecord
  belongs_to :portfolio

  validates :date,           presence: true, uniqueness: { scope: :portfolio_id }
  validates :total_value,    presence: true
  validates :cash_value,     presence: true
  validates :invested_value, presence: true

  scope :recent, -> { order(date: :desc) }
end
```

### 3.17 FxRate

```ruby
# app/models/fx_rate.rb
class FxRate < ApplicationRecord
  validates :base_currency,  presence: true
  validates :quote_currency, presence: true
  validates :rate,           presence: true, numericality: { greater_than: 0 }
  validates :fetched_at,     presence: true

  validates :base_currency, uniqueness: { scope: :quote_currency }

  scope :latest, -> { order(fetched_at: :desc) }

  def self.convert(amount, from:, to:)
    return amount if from == to
    rate = find_by(base_currency: from, quote_currency: to)&.rate
    rate ? amount * rate : nil
  end

  def self.last_refresh
    maximum(:fetched_at)
  end
end
```

### 3.18 AssetPriceHistory

```ruby
# app/models/asset_price_history.rb
class AssetPriceHistory < ApplicationRecord
  belongs_to :asset

  validates :date,  presence: true, uniqueness: { scope: :asset_id }
  validates :close, presence: true

  scope :for_period, ->(from, to) { where(date: from..to).order(:date) }
  scope :recent,     ->(days = 30) { where("date >= ?", days.days.ago).order(:date) }
end
```

### 3.19 Notification

```ruby
# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :notification_type, { alert_triggered: 0, earnings_reminder: 1, system: 2 }

  validates :title, presence: true

  scope :unread,  -> { where(read: false) }
  scope :recent,  -> { order(created_at: :desc).limit(20) }

  def mark_as_read!
    update!(read: true)
  end
end
```

### 3.20 AuditLog

```ruby
# app/models/audit_log.rb
# Para acciones de usuarios/admins (compliance, trazabilidad)
class AuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true

  scope :recent,    -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) if action.present? }
  scope :by_user,   ->(user_id) { where(user_id: user_id) if user_id.present? }
end
```

### 3.21 Dividend

```ruby
# app/models/dividend.rb
class Dividend < ApplicationRecord
  belongs_to :asset
  has_many   :dividend_payments, dependent: :destroy

  validates :ex_date,          presence: true, uniqueness: { scope: :asset_id }
  validates :amount_per_share, presence: true, numericality: { greater_than: 0 }

  scope :upcoming, -> { where("ex_date >= ?", Date.current).order(:ex_date) }
end
```

### 3.22 DividendPayment

```ruby
# app/models/dividend_payment.rb
class DividendPayment < ApplicationRecord
  belongs_to :portfolio
  belongs_to :dividend

  validates :shares_held,   presence: true, numericality: { greater_than: 0 }
  validates :total_amount,  presence: true

  scope :recent, -> { order(created_at: :desc) }
end
```

### 3.23 RememberToken

```ruby
# app/models/remember_token.rb
class RememberToken < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true
  validates :expires_at,   presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at < Time.current
  end

  def touch_last_used!
    update!(last_used_at: Time.current)
  end
end
```

---

## 4. Seeds (Datos de Ejemplo)

```ruby
# db/seeds.rb

puts "Seeding database..."

# --- Users ---
admin = User.create!(
  full_name: "Admin User",
  email: "admin@stockerly.com",
  password: "password123",
  role: :admin,
  is_verified: true
)

alex = User.create!(
  full_name: "Alex Thompson",
  email: "alex.thompson@example.com",
  password: "password123",
  role: :user,
  is_verified: true
)

sarah = User.create!(
  full_name: "Sarah Chen",
  email: "sarah.s@web3.io",
  password: "password123",
  role: :user
)

jdoe = User.create!(
  full_name: "John Doe",
  email: "john.doe@example.com",
  password: "password123",
  role: :user
)

# --- Portfolios y AlertPreferences (creados via event handlers en produccion, manual en seeds) ---
[admin, alex, sarah, jdoe].each do |user|
  Portfolio.create!(user: user, inception_date: user.created_at.to_date) unless user.portfolio
  AlertPreference.create!(user: user) unless user.alert_preference
end

# --- Assets ---
aapl = Asset.create!(name: "Apple Inc.",       symbol: "AAPL",    asset_type: :stock,  sector: "Technology",      exchange: "NASDAQ", data_source: "Polygon.io",    current_price: 189.43, change_percent_24h: 2.45,  market_cap: 2940000000000, pe_ratio: 31.25, div_yield: 0.52, volume: 58200000, shares_outstanding: 15500000000, price_updated_at: 2.minutes.ago)
tsla = Asset.create!(name: "Tesla, Inc.",      symbol: "TSLA",    asset_type: :stock,  sector: "Consumer Cyclical",exchange: "NASDAQ", data_source: "Polygon.io",    current_price: 176.54, change_percent_24h: -1.12, market_cap: 561000000000,  pe_ratio: 62.80, volume: 95300000, shares_outstanding: 3180000000, price_updated_at: 2.minutes.ago)
msft = Asset.create!(name: "Microsoft Corp.",  symbol: "MSFT",    asset_type: :stock,  sector: "Technology",      exchange: "NASDAQ", data_source: "Polygon.io",    current_price: 420.50, change_percent_24h: 0.81,  market_cap: 3120000000000, pe_ratio: 36.14, div_yield: 0.72, volume: 22100000, shares_outstanding: 7430000000, price_updated_at: 2.minutes.ago)
nvda = Asset.create!(name: "NVIDIA Corp.",     symbol: "NVDA",    asset_type: :stock,  sector: "Technology",      exchange: "NASDAQ", data_source: "Finnhub",       current_price: 894.52, change_percent_24h: 3.82,  market_cap: 2210000000000, pe_ratio: 72.50, div_yield: 0.02, volume: 41200000, shares_outstanding: 2470000000, price_updated_at: 2.minutes.ago)
oke  = Asset.create!(name: "Oneok Inc.",       symbol: "OKE",     asset_type: :stock,  sector: "Energy",          exchange: "NYSE",   data_source: "Polygon.io",    current_price: 87.42,  change_percent_24h: 1.24,  market_cap: 51200000000,   pe_ratio: 14.82, div_yield: 4.48, volume: 3100000, shares_outstanding: 585600000, price_updated_at: 5.minutes.ago)
btc  = Asset.create!(name: "Bitcoin",          symbol: "BTC",     asset_type: :crypto,                                                data_source: "CoinGecko API", current_price: 64231.00, change_percent_24h: 0.85, market_cap: 1260000000000, price_updated_at: 1.minute.ago)
eth  = Asset.create!(name: "Ethereum",         symbol: "ETH",     asset_type: :crypto,                                                data_source: "CoinGecko API", current_price: 3450.00,  change_percent_24h: -0.45, market_cap: 415000000000, sync_status: :disabled, price_updated_at: 1.hour.ago)
sol  = Asset.create!(name: "Solana",           symbol: "SOL",     asset_type: :crypto,                                                data_source: "CoinGecko API", current_price: 142.80,   change_percent_24h: 2.10, sync_status: :sync_issue, price_updated_at: 30.minutes.ago)
vix  = Asset.create!(name: "CBOE Volatility Index", symbol: "VIX", asset_type: :index,                            exchange: "CBOE",                                 current_price: 14.33,  change_percent_24h: -1.22, price_updated_at: 10.minutes.ago)
tsmc = Asset.create!(name: "TSMC",             symbol: "2330.TW", asset_type: :stock,  sector: "Technology",      exchange: "TWSE",   data_source: "Polygon.io",    current_price: 605.00, change_percent_24h: 0.50, price_updated_at: 15.minutes.ago)

# --- Trades & Positions for Alex ---
portfolio = alex.portfolio
portfolio.update!(buying_power: 8240.15, inception_date: Date.new(2023, 1, 12))

# Simular trades que generan posiciones
[
  { asset: aapl, shares: 50,  price: 150.20, currency: "USD", date: 1.year.ago },
  { asset: msft, shares: 30,  price: 280.15, currency: "USD", date: 10.months.ago },
  { asset: tsla, shares: 20,  price: 242.50, currency: "USD", date: 8.months.ago },
  { asset: nvda, shares: 15,  price: 420.00, currency: "USD", date: 6.months.ago },
  { asset: tsmc, shares: 100, price: 560.00, currency: "TWD", date: 3.months.ago },
].each do |t|
  position = Position.create!(
    portfolio: portfolio, asset: t[:asset], shares: t[:shares],
    avg_cost: t[:price], currency: t[:currency], status: :open, opened_at: t[:date]
  )
  Trade.create!(
    portfolio: portfolio, asset: t[:asset], position: position,
    side: :buy, shares: t[:shares], price_per_share: t[:price],
    total_amount: t[:shares] * t[:price], currency: t[:currency],
    executed_at: t[:date]
  )
end

# --- Watchlist for Alex ---
[aapl, tsla, btc, nvda, msft].each do |asset|
  WatchlistItem.create!(user: alex, asset: asset, entry_price: asset.current_price)
end

# --- Alert Rules for Alex ---
AlertRule.create!(user: alex, asset_symbol: "AAPL",    condition: :price_crosses_above, threshold_value: 195.00, status: :active)
AlertRule.create!(user: alex, asset_symbol: "TSLA",    condition: :rsi_oversold,        threshold_value: 30,     status: :paused)
AlertRule.create!(user: alex, asset_symbol: "BTC/USD", condition: :day_change_percent,  threshold_value: 5.0,    status: :active)

# --- Alert Events ---
AlertEvent.create!(user: alex, asset_symbol: "MSFT", message: "Price crossed above resistance at $420.50", event_status: :triggered, triggered_at: 2.minutes.ago)
AlertEvent.create!(user: alex, asset_symbol: "AMZN", message: "Fell below target of $175.00",              event_status: :triggered, triggered_at: 15.minutes.ago)
AlertEvent.create!(user: alex, asset_symbol: "NVDA", message: "24h volume spiked by 12.5%",                event_status: :settled,   triggered_at: 1.hour.ago)
AlertEvent.create!(user: alex, asset_symbol: "META", message: "Golden cross pattern detected on 4H chart", event_status: :settled,   triggered_at: 2.hours.ago)

# --- Alert Preferences ---
alex.alert_preference.update!(browser_push: true, email_digest: true, sms_notifications: false)

# --- Market Indices ---
MarketIndex.create!(name: "S&P 500",     symbol: "SPX", value: 5214.33,  change_percent: 0.42,  exchange: "NYSE",   is_open: true)
MarketIndex.create!(name: "NASDAQ 100",  symbol: "NDX", value: 18322.40, change_percent: 1.15,  exchange: "NASDAQ", is_open: true)
MarketIndex.create!(name: "DOW JONES",   symbol: "DJI", value: 39127.14, change_percent: -0.12, exchange: "NYSE",   is_open: true)
MarketIndex.create!(name: "FTSE 100",    symbol: "UKX", value: 7935.09,  change_percent: 0.28,  exchange: "LSE",    is_open: false)

# --- Trend Scores ---
TrendScore.create!(asset: aapl, score: 88, label: :strong,    direction: :upward,   calculated_at: Time.current)
TrendScore.create!(asset: tsla, score: 42, label: :weakening, direction: :downward, calculated_at: Time.current)
TrendScore.create!(asset: nvda, score: 96, label: :parabolic, direction: :upward,   calculated_at: Time.current)
TrendScore.create!(asset: vix,  score: 25, label: :sideways,  direction: :downward, calculated_at: Time.current)
TrendScore.create!(asset: oke,  score: 94, label: :strong,    direction: :upward,   calculated_at: Time.current)

# --- Earnings Events ---
[
  { asset: tsla, report_date: Date.new(2023, 10, 18), timing: :after_market_close, estimated_eps: 0.73 },
  { asset: msft, report_date: Date.new(2023, 10, 24), timing: :before_market_open, estimated_eps: 2.65 },
  { asset: nvda, report_date: Date.new(2023, 10, 25), timing: :after_market_close, estimated_eps: 3.36 },
  { asset: aapl, report_date: Date.new(2023, 10, 26), timing: :after_market_close, estimated_eps: 1.39 },
].each { |attrs| EarningsEvent.create!(**attrs) }

# --- News Articles ---
NewsArticle.create!(title: "Apple's Vision Pro Sales Exceed Expectations in First Quarter",  summary: "New supply chain data suggests strong demand for the spatial computing headset across institutional markets.", source: "Bloomberg", related_ticker: "AAPL", published_at: 2.hours.ago, image_url: "https://placehold.co/120x80", url: "https://example.com/aapl-vision-pro")
NewsArticle.create!(title: "Microsoft Announces Multi-Billion Dollar AI Infrastructure Plan", summary: "The tech giant plans to double its data center capacity to support growing enterprise AI demands globally.", source: "Reuters",   related_ticker: "MSFT", published_at: 5.hours.ago, image_url: "https://placehold.co/120x80", url: "https://example.com/msft-ai")
NewsArticle.create!(title: "Tesla Shifts Focus to Next-Gen Platform for Affordable EV",      summary: "The company is reportedly restructuring its autonomous AI unit as it pivots toward a sub-$25,000 electric vehicle.", source: "WSJ",       related_ticker: "TSLA", published_at: 8.hours.ago, image_url: "https://placehold.co/120x80", url: "https://example.com/tsla-ev")

# --- Portfolio Snapshots for Alex ---
5.downto(1).each do |days_ago|
  PortfolioSnapshot.create!(
    portfolio: portfolio,
    date: days_ago.days.ago.to_date,
    total_value: portfolio.total_value + rand(-500.0..500.0),
    cash_value: portfolio.buying_power,
    invested_value: portfolio.total_value - portfolio.buying_power + rand(-300.0..300.0)
  )
end

# --- FX Rates ---
FxRate.create!(base_currency: "USD", quote_currency: "EUR", rate: 0.92,   fetched_at: 1.hour.ago)
FxRate.create!(base_currency: "USD", quote_currency: "MXN", rate: 17.25,  fetched_at: 1.hour.ago)
FxRate.create!(base_currency: "USD", quote_currency: "GBP", rate: 0.79,   fetched_at: 1.hour.ago)
FxRate.create!(base_currency: "USD", quote_currency: "TWD", rate: 31.50,  fetched_at: 1.hour.ago)

# --- Dividends ---
aapl_div = Dividend.create!(asset: aapl, ex_date: 1.month.ago.to_date, pay_date: 3.weeks.ago.to_date, amount_per_share: 0.24, currency: "USD")
DividendPayment.create!(portfolio: portfolio, dividend: aapl_div, shares_held: 50, total_amount: 12.00, received_at: 3.weeks.ago)

# --- Notifications for Alex ---
Notification.create!(user: alex, title: "MSFT crossed $420.50", body: "Your price alert for Microsoft was triggered.", notification_type: :alert_triggered, notifiable: AlertEvent.first)
Notification.create!(user: alex, title: "AAPL earnings tomorrow", body: "Apple reports Q4 earnings after market close.", notification_type: :earnings_reminder)

# --- System Logs ---
SystemLog.create!(task_name: "FX Rate Update",         module_name: "Finance",     severity: :success, duration_seconds: 1.2)
SystemLog.create!(task_name: "Shopify Price Sync",      module_name: "Marketplace", severity: :error,   duration_seconds: 5.4, error_message: "Auth Exception: Connection timeout after 5000ms")
SystemLog.create!(task_name: "Inventory Audit",         module_name: "Warehouse",   severity: :warning, duration_seconds: 12.8, error_message: "Partial sync: 3 items skipped")
SystemLog.create!(task_name: "Daily Backup",            module_name: "Core",        severity: :success, duration_seconds: 45.0)
SystemLog.create!(task_name: "User Session Clean-up",   module_name: "Auth",        severity: :success, duration_seconds: 0.8)

# --- Audit Logs ---
AuditLog.create!(user: admin, action: "admin.assets.create", auditable: aapl, changes: { after: { symbol: "AAPL" } }, ip_address: "127.0.0.1")
AuditLog.create!(user: admin, action: "admin.integrations.connect", auditable: Integration.first, changes: { after: { provider: "Polygon.io" } }, ip_address: "127.0.0.1") if Integration.any?

# --- Integrations ---
Integration.create!(provider_name: "Polygon.io",  provider_type: "Stocks & Forex",   api_key_encrypted: "pk_live_abc123xyz789", connection_status: :connected, last_sync_at: 2.minutes.ago)
Integration.create!(provider_name: "CoinGecko",   provider_type: "Cryptocurrency",   api_key_encrypted: "cg_demo_key_456def",   connection_status: :syncing,   last_sync_at: 1.hour.ago)

puts "Seeded: #{User.count} users, #{Asset.count} assets, #{Position.count} positions, #{Trade.count} trades, #{AlertRule.count} alert rules, #{EarningsEvent.count} earnings, #{NewsArticle.count} news, #{Notification.count} notifications, #{PortfolioSnapshot.count} snapshots, #{FxRate.count} FX rates, #{Dividend.count} dividends."
```

---

## 5. Comandos para Generar

```bash
# Generar todos los modelos (migraciones escritas manualmente arriba)
bin/rails generate model User full_name:string email:string password_digest:string avatar_url:string role:integer status:integer is_verified:boolean preferred_currency:string password_reset_token:string password_reset_sent_at:datetime --no-migration
bin/rails generate model Asset name:string symbol:string asset_type:integer sector:string exchange:string data_source:string sync_status:integer current_price:decimal change_percent_24h:decimal market_cap:decimal pe_ratio:decimal div_yield:decimal volume:bigint shares_outstanding:bigint price_updated_at:datetime --no-migration
bin/rails generate model Portfolio user:references buying_power:decimal inception_date:date --no-migration
bin/rails generate model Position portfolio:references asset:references shares:decimal avg_cost:decimal currency:string status:integer opened_at:datetime closed_at:datetime --no-migration
bin/rails generate model Trade portfolio:references asset:references position:references side:integer shares:decimal price_per_share:decimal total_amount:decimal fee:decimal currency:string executed_at:datetime --no-migration
bin/rails generate model WatchlistItem user:references asset:references entry_price:decimal --no-migration
bin/rails generate model AlertRule user:references asset_symbol:string condition:integer threshold_value:decimal status:integer --no-migration
bin/rails generate model AlertEvent alert_rule:references user:references asset_symbol:string message:string event_status:integer triggered_at:datetime --no-migration
bin/rails generate model AlertPreference user:references browser_push:boolean email_digest:boolean sms_notifications:boolean --no-migration
bin/rails generate model EarningsEvent asset:references report_date:date timing:integer estimated_eps:decimal actual_eps:decimal --no-migration
bin/rails generate model NewsArticle title:string summary:text image_url:string source:string related_ticker:string url:string published_at:datetime --no-migration
bin/rails generate model MarketIndex name:string symbol:string value:decimal change_percent:decimal exchange:string is_open:boolean --no-migration
bin/rails generate model TrendScore asset:references score:integer label:integer direction:integer calculated_at:datetime --no-migration
bin/rails generate model SystemLog task_name:string module_name:string severity:integer duration_seconds:decimal error_message:text log_uid:string --no-migration
bin/rails generate model Integration provider_name:string provider_type:string api_key_encrypted:string connection_status:integer last_sync_at:datetime --no-migration
bin/rails generate model PortfolioSnapshot portfolio:references date:date total_value:decimal cash_value:decimal invested_value:decimal --no-migration
bin/rails generate model FxRate base_currency:string quote_currency:string rate:decimal fetched_at:datetime --no-migration
bin/rails generate model AssetPriceHistory asset:references date:date open:decimal high:decimal low:decimal close:decimal volume:bigint --no-migration
bin/rails generate model Notification user:references title:string body:text notification_type:integer read:boolean notifiable:references{polymorphic} --no-migration
bin/rails generate model AuditLog user:references action:string auditable:references{polymorphic} changes:jsonb ip_address:string --no-migration
bin/rails generate model Dividend asset:references ex_date:date pay_date:date amount_per_share:decimal currency:string --no-migration
bin/rails generate model DividendPayment portfolio:references dividend:references shares_held:decimal total_amount:decimal received_at:datetime --no-migration
bin/rails generate model RememberToken user:references token_digest:string expires_at:datetime last_used_at:datetime ip_address:string user_agent:string --no-migration

# Ejecutar migraciones y seeds
bin/rails db:create db:migrate db:seed
```
