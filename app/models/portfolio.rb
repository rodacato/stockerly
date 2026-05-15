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
    positions_total = open_positions.includes(:asset).sum do |p|
      position_market_value_in(p, currency)
    end
    positions_total + buying_power_in(currency)
  end

  def total_unrealized_gain(currency: user.preferred_currency)
    open_positions.includes(:asset).sum do |p|
      raw_gain = p.shares * ((p.asset.current_price || 0) - p.avg_cost)
      convert(raw_gain, from: p.asset.currency, to: currency)
    end
  end

  def allocation_by_sector(currency: user.preferred_currency)
    open_positions.includes(:asset).group_by { |p| p.asset.sector }.transform_values do |group|
      group.sum { |p| position_market_value_in(p, currency) }
    end
  end

  def allocation_by_asset_type(currency: user.preferred_currency)
    open_positions.includes(:asset).group_by { |p| p.asset.asset_type }.transform_values do |group|
      group.sum { |p| position_market_value_in(p, currency) }
    end
  end

  def yesterday_snapshot
    snapshots.where(date: Date.yesterday).first
  end

  private

  def position_market_value_in(position, target_currency)
    raw = position.shares * (position.asset.current_price || 0)
    convert(raw, from: position.asset.currency, to: target_currency)
  end

  def buying_power_in(target_currency)
    convert(buying_power, from: buying_power_currency, to: target_currency)
  end

  def convert(amount, from:, to:)
    return amount.to_d if from == to

    converted = FxRate.convert(amount.to_d, from: from, to: to)
    raise "Missing FX rate #{from}->#{to} (Portfolio##{id})" if converted.nil?
    converted
  end
end
