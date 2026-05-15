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

  # buying_power is always denominated in the owner's preferred_currency
  # (deposits/withdrawals happen in that currency on Stockerly's books).
  def buying_power_currency
    user.preferred_currency
  end

  def total_value(currency: user.preferred_currency)
    positions_total = open_positions_with_assets.sum do |p|
      position_market_value_in(p, currency)
    end
    positions_total + buying_power_in(currency)
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
  def convert(amount, from:, to:)
    return amount.to_d if from == to

    rate = fx_rate_cache[[ from, to ]] ||= FxRate.find_by(base_currency: from, quote_currency: to)&.rate
    raise "Missing FX rate #{from}->#{to} (Portfolio##{id})" if rate.nil?

    amount.to_d * rate
  end

  private

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

  def buying_power_in(target_currency)
    convert(buying_power, from: buying_power_currency, to: target_currency)
  end

  def fx_rate_cache
    @fx_rate_cache ||= {}
  end
end
