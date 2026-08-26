class MarketIndexHistory < ApplicationRecord
  belongs_to :market_index

  validates :date, presence: true, uniqueness: { scope: %i[market_index_id interval] }
  validates :close_value, presence: true, numericality: { greater_than: 0 }
  validates :source, presence: true
  validates :interval, inclusion: { in: AssetPriceHistory::INTERVALS }
  validates :status, inclusion: { in: AssetPriceHistory::STATUSES }

  scope :recent, -> { order(date: :desc) }
  scope :for_period, ->(from, to) { where(date: from..to).order(:date) }
end
