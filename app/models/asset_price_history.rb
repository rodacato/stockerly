class AssetPriceHistory < ApplicationRecord
  belongs_to :asset

  validates :date,  presence: true, uniqueness: { scope: :asset_id }
  validates :close, presence: true

  scope :for_period, ->(from, to) { where(date: from..to).order(:date) }
  scope :recent,     ->(days = 30) { where("date >= ?", days.days.ago).order(:date) }
end
