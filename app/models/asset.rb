class Asset < ApplicationRecord
  enum :asset_type, { stock: 0, crypto: 1, index: 2, etf: 3, fixed_income: 4 }, prefix: true
  enum :sync_status, { active: 0, disabled: 1, sync_issue: 2 }

  has_many :positions,              dependent: :destroy
  has_many :trades,                 dependent: :destroy
  has_many :watchlist_items,       dependent: :destroy
  has_many :watching_users,        through: :watchlist_items, source: :user
  has_many :trend_scores,          dependent: :destroy
  has_many :earnings_events,       dependent: :destroy
  has_many :asset_price_histories, dependent: :destroy
  has_many :dividends,             dependent: :destroy

  validates :name,   presence: true
  validates :symbol, presence: true, uniqueness: { case_sensitive: false }

  scope :stocks,      -> { where(asset_type: :stock) }
  scope :cryptos,     -> { where(asset_type: :crypto) }
  scope :etfs,          -> { where(asset_type: :etf) }
  scope :fixed_incomes, -> { where(asset_type: :fixed_income) }
  scope :syncing,     -> { where(sync_status: :active) }
  scope :by_sector,   ->(sector) { where(sector: sector) if sector.present? }
  scope :by_country,  ->(country) { where(country: country) if country.present? }

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
end
