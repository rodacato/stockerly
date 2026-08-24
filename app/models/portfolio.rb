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

  def total_value(currency: user.preferred_currency)
    invested_value(currency: currency)
  end

  def invested_value(currency: user.preferred_currency)
    open_positions_with_assets.sum do |p|
      position_market_value_in(p, currency)
    end
  end

  # Honest gain/loss in the target currency: market value (today's FX) minus
  # cost basis (each trade's historical FX). The previous implementation
  # computed the gain in asset currency and converted that delta — which
  # ignored the FX gain/loss on the principal itself (Gemini #57). Example:
  # bought $100 of AAPL when FX was 20 MXN/USD (cost 2000 MXN); today
  # AAPL is still $100 but FX is 17 MXN/USD (value 1700 MXN). The user
  # actually lost 300 MXN; the old formula reported 0.
  def total_unrealized_gain(currency: user.preferred_currency)
    open_positions_with_trades.sum do |p|
      market = position_market_value_in(p, currency)
      cost   = p.cost_basis_in(currency)
      market - cost
    end
  end

  def allocation_by_sector(currency: user.preferred_currency)
    open_positions_with_assets.group_by { |p| p.asset.sector }.transform_values do |group|
      group.sum { |p| position_market_value_in(p, currency) }
    end
  end

  def allocation_by_asset_type(currency: user.preferred_currency)
    open_positions_with_assets.group_by { |p| p.asset.asset_type }.transform_values do |group|
      group.sum { |p| position_market_value_in(p, currency) }
    end
  end

  def yesterday_snapshot
    snapshots.where(date: Date.yesterday).first
  end

  # Public so PortfolioSummary and PeriodReturnsCalculator can route through
  # the per-instance FX cache below — collapses what would otherwise be one
  # FxRate.find_by per position/snapshot into a single query per pair.
  # `at_date` makes a historical figure honest (ADR-009): revaluing an old
  # snapshot at today's rate reports FX movement on the principal as "no
  # change". Without it the behaviour is unchanged — today's rate, from the
  # single-row-per-pair `fx_rates`.
  def convert(amount, from:, to:, at_date: nil)
    return amount.to_d if from == to

    rate = at_date ? historical_rate(from, to, at_date) : current_rate(from, to)
    raise "Missing FX rate #{from}->#{to} (Portfolio##{id})" if rate.nil?

    amount.to_d * rate
  end

  private

  def current_rate(from, to)
    fx_rate_cache[[ from, to ]] ||= FxRate.find_by(base_currency: from, quote_currency: to)&.rate
  end

  # Falls back to today's rate when history has no entry on or before the date,
  # which is what an instance sees before its first backfill. Better a current
  # rate than a raised exception on a screen.
  def historical_rate(from, to, date)
    fx_rate_cache[[ from, to, date ]] ||=
      FxRateHistory.rate_on(base: from, quote: to, date: date) || current_rate(from, to)
  end

  def open_positions_with_assets
    open_positions.includes(:asset)
  end

  def open_positions_with_trades
    open_positions.includes(:asset, :trades)
  end

  def position_market_value_in(position, target_currency)
    raw = position.shares * (position.asset.current_price || 0)
    convert(raw, from: position.asset.currency, to: target_currency)
  end

  def fx_rate_cache
    @fx_rate_cache ||= {}
  end
end
