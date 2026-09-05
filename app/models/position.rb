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
  #
  # Operates on the in-memory `trades` collection so a caller can preload
  # via `includes(:trades)` and avoid a per-position query (the call site
  # in PortfolioSummary#total_invested does this).
  def avg_cost_in(target_currency)
    return avg_cost.to_d if target_currency == asset&.currency

    weighted_avg_cost(trades.select { |t| t.side == "buy" && t.discarded_at.nil? }, target_currency)
  end

  def cost_basis_in(target_currency)
    shares * avg_cost_in(target_currency)
  end

  # A trade may be paid in a currency other than its asset's (the SIC settles
  # a US-listed asset in pesos), so buys are stated in the asset's unit first.
  def recalculate_avg_cost!
    cost = weighted_avg_cost(trades.kept.where(side: :buy).to_a, asset.currency)
    return if cost.zero?

    update!(avg_cost: cost)
  end

  def shares_from_trades
    trades.kept.buys.sum(:shares) - trades.kept.sells.sum(:shares)
  end

  # After a trade is added, edited or discarded the position is re-derived from
  # its trades rather than adjusted in place, so the two agree by construction.
  def resync_from_trades!
    recalculate_avg_cost!

    remaining = shares_from_trades
    if remaining.zero?
      update!(status: :closed, shares: remaining, closed_at: Time.current)
    else
      update!(shares: remaining, status: :open, closed_at: nil)
    end
  end

  private

  def weighted_avg_cost(buys, target_currency)
    total_shares = buys.sum(&:shares)
    return 0.to_d if total_shares.zero?

    total = buys.sum { |t| t.shares * t.price_per_share * Trading::Domain::ExecutionRate.multiplier(trade: t, target: target_currency) }
    (total / total_shares).to_d
  end
end
