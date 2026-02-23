class MarketIndex < ApplicationRecord
  validates :name,   presence: true
  validates :symbol, presence: true, uniqueness: true

  scope :major, -> { where(symbol: %w[SPX NDX DJI UKX IPC]) }

  def self.vix
    find_by(symbol: "VIX")
  end
end
