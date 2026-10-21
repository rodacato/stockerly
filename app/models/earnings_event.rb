class EarningsEvent < ApplicationRecord
  belongs_to :asset

  enum :timing, { before_market_open: 0, after_market_close: 1 }

  validates :report_date, presence: true, uniqueness: { scope: :asset_id }
  validates :timing,      presence: true

  scope :for_month, ->(date) {
    where(report_date: date.all_month)
  }
  scope :upcoming, -> { where(report_date: Date.current..).order(:report_date) }
  scope :reported, -> { where.not(actual_eps: nil) }
  scope :recent_window, ->(days = 7) {
    where(report_date: (Date.current - days.days)..(Date.current - 1)).order(report_date: :desc)
  }
  scope :upcoming_window, ->(days = 7) {
    where(report_date: Date.current..(Date.current + days.days)).order(:report_date)
  }
  scope :for_market, ->(market) {
    case market.to_s
    when "BMV", "NASDAQ", "NYSE"
      joins(:asset).where(assets: { exchange: market })
    else
      all
    end
  }
end
