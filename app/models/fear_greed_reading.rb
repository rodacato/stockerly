class FearGreedReading < ApplicationRecord
  CLASSIFICATIONS = {
    (0..24)  => "Extreme Fear",
    (25..44) => "Fear",
    (45..55) => "Neutral",
    (56..74) => "Greed",
    (75..100) => "Extreme Greed"
  }.freeze

  validates :index_type, presence: true, inclusion: { in: %w[crypto stocks] }
  validates :value, presence: true, numericality: { in: 0..100 }
  validates :classification, presence: true
  validates :source, presence: true
  validates :fetched_at, presence: true

  scope :crypto, -> { where(index_type: "crypto") }
  scope :stocks, -> { where(index_type: "stocks") }
  scope :recent, -> { order(fetched_at: :desc).limit(30) }

  def self.latest_crypto = crypto.order(fetched_at: :desc).first
  def self.latest_stocks = stocks.order(fetched_at: :desc).first

  def stale?
    fetched_at < 25.hours.ago
  end

  def self.classify(value)
    CLASSIFICATIONS.find { |range, _| range.cover?(value) }&.last || "Neutral"
  end
end
