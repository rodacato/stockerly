class Position < ApplicationRecord
  belongs_to :portfolio
  belongs_to :asset
  has_many   :trades, dependent: :destroy

  delegate :currency, to: :asset, allow_nil: true

  enum :status, { open: 0, closed: 1 }

  validates :shares,   presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :avg_cost, presence: true, numericality: { greater_than: 0 }

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

  # Weighted-average cost-per-share in the target currency, derived from
  # each buy trade's historical fx_rate_at_execution. Falls back to the
  # native asset-currency avg_cost when the target matches asset.currency.
  def avg_cost_in(target_currency)
    return avg_cost.to_d if target_currency == asset&.currency

    buys = trades.kept.where(side: :buy)
    return 0.to_d if buys.empty?

    total_shares    = buys.sum(:shares)
    total_user_cost = buys.sum("shares * price_per_share * COALESCE(fx_rate_at_execution, 0)")
    return 0.to_d if total_shares.zero?

    (total_user_cost / total_shares).to_d
  end

  def cost_basis_in(target_currency)
    shares * avg_cost_in(target_currency)
  end

  def recalculate_avg_cost!
    buy_trades = trades.kept.where(side: :buy)
    return if buy_trades.empty?

    total_shares = buy_trades.sum(:shares)
    weighted_cost = buy_trades.sum("shares * price_per_share")
    update!(avg_cost: weighted_cost / total_shares)
  end
end
