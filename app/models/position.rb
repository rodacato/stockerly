class Position < ApplicationRecord
  # A split rewrites each leg at the column's scale, so a sold-out position can
  # sum to a few units of the last digit; that is zero, not an oversell.
  SHARE_RESIDUE = BigDecimal("1e-9")

  belongs_to :portfolio
  belongs_to :asset
  has_many   :trades, dependent: :destroy

  delegate :currency, to: :asset, allow_nil: true

  enum :status, { open: 0, closed: 1 }

  validates :shares,   presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :avg_cost, presence: true, numericality: { greater_than: 0 }

  def market_value
    shares * asset.current_price if asset.current_price
  end

  def total_gain
    shares * (asset.current_price - avg_cost) if asset.current_price
  end

  def total_gain_percent
    return nil unless asset.current_price
    return 0 if avg_cost.zero?
    (asset.current_price - avg_cost) / avg_cost * 100
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

    running_avg_cost(trades.select { |t| t.discarded_at.nil? }, target_currency)
  end

  def cost_basis_in(target_currency)
    shares * avg_cost_in(target_currency)
  end

  # A trade may be paid in a currency other than its asset's (the SIC settles
  # a US-listed asset in pesos), so buys are stated in the asset's unit first.
  def recalculate_avg_cost!
    cost = running_avg_cost(trades.kept.to_a, asset.currency)
    return if cost.zero?

    update!(avg_cost: cost)
  end

  def shares_from_trades
    remaining = trades.kept.buys.sum(:shares) - trades.kept.sells.sum(:shares)
    remaining.abs < SHARE_RESIDUE ? 0.to_d : remaining
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

  # A sale takes shares out at the average they carry and leaves it as it is;
  # a buy averages against what is still held. Sold out, the next buy starts over.
  def running_avg_cost(kept_trades, target_currency)
    held = 0.to_d
    cost = 0.to_d
    kept_trades.sort_by { |t| [ t.executed_at, t.id.to_i ] }.each do |trade|
      shares = trade.shares.to_d
      if trade.side.to_s == "buy"
        price = trade.price_per_share.to_d * Trading::Domain::ExecutionRate.multiplier(trade: trade, target: target_currency)
        cost = ((held * cost) + (shares * price)) / (held + shares)
        held += shares
      else
        held = [ held - shares, 0 ].max
      end
    end
    cost
  end
end
