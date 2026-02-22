# Takes a daily portfolio snapshot for every portfolio.
# Runs once per day (configured in recurring.yml).
class TakeSnapshotsJob < ApplicationJob
  queue_as :default

  def perform
    Portfolio.includes(:positions, positions: :asset).find_each do |portfolio|
      take_snapshot(portfolio)
    end
  end

  private

  def take_snapshot(portfolio)
    invested = portfolio.open_positions.sum { |p| p.market_value }
    total = invested + portfolio.buying_power

    portfolio.snapshots.create!(
      date: Date.current,
      total_value: total,
      cash_value: portfolio.buying_power,
      invested_value: invested
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # Snapshot already taken for today — idempotent
  end
end
