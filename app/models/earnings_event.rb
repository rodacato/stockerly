class EarningsEvent < ApplicationRecord
  belongs_to :asset

  enum :timing, { before_market_open: 0, after_market_close: 1 }

  validates :report_date, presence: true, uniqueness: { scope: :asset_id }
  validates :timing,      presence: true

  scope :for_month, ->(date) {
    where(report_date: date.beginning_of_month..date.end_of_month)
  }
  scope :upcoming, -> { where("report_date >= ?", Date.current).order(:report_date) }
  scope :reported, -> { where.not(actual_eps: nil) }

  # Returns :beat, :miss, or nil (pending)
  def beat_miss
    return nil if actual_eps.nil? || estimated_eps.nil?

    actual_eps >= estimated_eps ? :beat : :miss
  end

  # Returns the percentage difference between actual and estimated EPS
  def eps_surprise_percent
    return nil if actual_eps.nil? || estimated_eps.nil? || estimated_eps.zero?

    ((actual_eps - estimated_eps) / estimated_eps.abs * 100).round(1)
  end
end
