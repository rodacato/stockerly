class Asset < ApplicationRecord
  SUPPORTED_CURRENCIES = %w[USD MXN].freeze

  enum :asset_type, { stock: 0, crypto: 1, index: 2, etf: 3, fixed_income: 4 }, prefix: true
  # Binary and user-controlled: active = synced automatically, disabled = paused
  # by the user. A failed sync never changes this — it sets last_sync_error.
  enum :sync_status, { active: 0, disabled: 1 }

  has_many :positions,              dependent: :destroy
  has_many :trades,                 dependent: :destroy
  has_many :watchlist_items,       dependent: :destroy
  has_many :watching_users,        through: :watchlist_items, source: :user
  has_many :trend_scores,          dependent: :destroy
  has_many :earnings_events,       dependent: :destroy
  has_many :asset_price_histories, dependent: :destroy
  has_many :dividends,             dependent: :destroy
  has_many :stock_splits,          dependent: :destroy
  has_many :financial_statements,  dependent: :destroy
  has_many :asset_fundamentals,    dependent: :destroy
  has_many :technical_observations, dependent: :destroy
  has_one :technical_reading, dependent: :destroy

  # Measured, not assumed: 50 of 54 production rows are tickers over [A-Z0-9.-]
  # (the BMV's carry `.MX`); the 4 CETES are Banxico identifiers, not tickers.
  SYMBOL_FORMAT = /\A[A-Z0-9.\-]{1,20}\z/
  FIXED_INCOME_SYMBOL_FORMAT = /\A[A-Z0-9._\-]{1,20}\z/

  validates :name,     presence: true
  validates :symbol,   presence: true, uniqueness: { case_sensitive: false }
  # Split by type: only the ticker alphabet can reach the TradingView widget,
  # which is what lets that consumer stop carrying a guard of its own.
  validates :symbol, format: { with: SYMBOL_FORMAT }, allow_blank: true,
                     unless: :asset_type_fixed_income?
  validates :symbol, format: { with: FIXED_INCOME_SYMBOL_FORMAT }, allow_blank: true,
                     if: :asset_type_fixed_income?
  validates :currency, presence: true, inclusion: { in: SUPPORTED_CURRENCIES }

  scope :stocks,      -> { where(asset_type: :stock) }
  scope :cryptos,     -> { where(asset_type: :crypto) }
  scope :etfs,          -> { where(asset_type: :etf) }
  scope :fixed_incomes, -> { where(asset_type: :fixed_income) }
  scope :syncing,     -> { where(sync_status: :active) }
  scope :with_sync_error, -> { where.not(last_sync_error: nil) }
  scope :by_sector,   ->(sector) { where(sector: sector) if sector.present? }
  # Providers disagree on how to name the same instrument: Yahoo says
  # WALMEX.MX, the BMV says WALMEX*, Alpaca says AAPL. `symbol` stays what the
  # user reads; overrides live here, keyed by the gateway's PROVIDER.
  def symbol_for(provider)
    provider_symbols[provider.to_s].presence || symbol
  end

  def gateway_symbols
    provider_symbols.merge("default" => symbol)
  end

  scope :by_country,  ->(country) { where(country: country) if country.present? }

  # Which market routes this asset. Country is the only signal the catalogue
  # carries, and everything not Mexican is priced by a US-market source.
  def market
    country == "MX" ? :mx : :us
  end

  scope :high_priority, -> {
    watched = WatchlistItem.select(:asset_id)
    held = Position.where(status: :open).select(:asset_id)
    alerted_symbols = AlertRule.where(status: :active).select(:asset_symbol).distinct

    where(id: watched)
      .or(where(id: held))
      .or(where(symbol: alerted_symbols))
  }

  scope :low_priority, -> {
    where.not(id: high_priority.select(:id))
  }

  def latest_trend_score
    trend_scores.order(calculated_at: :desc).first
  end

  def price_stale?
    price_updated_at.nil? || price_updated_at < 15.minutes.ago
  end

  def last_sync_ok?
    last_sync_error.blank?
  end
end
