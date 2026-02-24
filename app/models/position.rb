class Position < ApplicationRecord
  belongs_to :portfolio
  belongs_to :asset
  has_many   :trades, dependent: :destroy

  enum :status, { open: 0, closed: 1 }

  validates :shares,   presence: true, numericality: { greater_than_or_equal_to: 0 }
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

  def recalculate_avg_cost!
    buy_trades = trades.where(side: :buy)
    return if buy_trades.empty?

    total_shares = buy_trades.sum(:shares)
    weighted_cost = buy_trades.sum("shares * price_per_share")
    update!(avg_cost: weighted_cost / total_shares)
  end
end
