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

  def total_value
    open_positions.sum { |p| p.shares * (p.asset.current_price || 0) } + buying_power
  end

  def total_unrealized_gain
    open_positions.sum { |p| p.shares * ((p.asset.current_price || 0) - p.avg_cost) }
  end

  def allocation_by_sector
    open_positions
      .joins(:asset)
      .group("assets.sector")
      .sum("positions.shares * assets.current_price")
  end

  def allocation_by_asset_type
    open_positions
      .joins(:asset)
      .group("assets.asset_type")
      .sum("positions.shares * assets.current_price")
  end

  def yesterday_snapshot
    snapshots.where(date: Date.yesterday).first
  end
end
