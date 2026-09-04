class AssetPriceHistory < ApplicationRecord
  INTERVALS = %w[1d 1h 5m 1m].freeze
  STATUSES = %w[confirmed provisional disposable].freeze

  belongs_to :asset

  validates :date, presence: true, uniqueness: { scope: %i[asset_id interval] }
  validates :close, presence: true
  validates :source, presence: true
  validates :interval, inclusion: { in: INTERVALS }
  validates :status, inclusion: { in: STATUSES }

  scope :for_period, ->(from, to) { where(date: from..to).order(:date) }
  scope :recent,     ->(days = 30) { where(date: days.days.ago..).order(:date) }
  scope :daily,      -> { where(interval: "1d") }
end
