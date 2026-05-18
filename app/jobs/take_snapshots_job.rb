# Takes a daily portfolio snapshot for every portfolio.
# Runs once per day (configured in recurring.yml).
class TakeSnapshotsJob < ApplicationJob
  queue_as :default

  def perform
    Portfolio.includes(:user, :positions, positions: :asset).find_each do |portfolio|
      take_snapshot(portfolio)
    end
  end

  private

  # Snapshots are persisted in the user's preferred_currency so that the
  # dashboard and performance chart can read a single coherent unit. Summing
  # raw position#market_value across currencies (the pre-fix behavior) added
  # USD + MXN as if same unit and produced fiction for mixed portfolios.
  def take_snapshot(portfolio)
    currency = portfolio.user.preferred_currency

    portfolio.snapshots.create!(
      date: Date.current,
      currency: currency,
      total_value: portfolio.total_value(currency: currency),
      cash_value: portfolio.buying_power,
      invested_value: portfolio.invested_value(currency: currency)
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # Snapshot already taken for today — idempotent
  end
end
