class MarketIndexHistory < ApplicationRecord
  belongs_to :market_index

  validates :date, presence: true, uniqueness: { scope: :market_index_id }
  validates :close_value, presence: true, numericality: { greater_than: 0 }

  scope :recent, -> { order(date: :desc) }
  scope :for_period, ->(from, to) { where(date: from..to).order(:date) }
end
