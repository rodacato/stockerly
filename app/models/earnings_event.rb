class EarningsEvent < ApplicationRecord
  belongs_to :asset

  enum :timing, { before_market_open: 0, after_market_close: 1 }

  validates :report_date, presence: true, uniqueness: { scope: :asset_id }
  validates :timing,      presence: true

  scope :for_month, ->(date) {
    where(report_date: date.beginning_of_month..date.end_of_month)
  }
  scope :upcoming, -> { where("report_date >= ?", Date.current).order(:report_date) }
end
