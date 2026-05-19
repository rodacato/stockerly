class MarketIndex < ApplicationRecord
  has_many :market_index_histories, dependent: :destroy

  validates :name,   presence: true
  validates :symbol, presence: true, uniqueness: true

  # MAJOR_SYMBOLS is also the display order (S09 #92): IPC first per MX-first
  # vision, then the US/UK indices. The `array_position` ORDER preserves
  # this regardless of insert order in the DB.
  MAJOR_SYMBOLS = %w[IPC SPX NDX DJI UKX].freeze

  scope :major, lambda {
    order_clause = sanitize_sql_array([ "array_position(ARRAY[?]::text[], symbol::text)", MAJOR_SYMBOLS ])
    where(symbol: MAJOR_SYMBOLS).order(Arel.sql(order_clause))
  }

  def self.vix
    find_by(symbol: "VIX")
  end
end
