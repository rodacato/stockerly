class FearGreedReading < ApplicationRecord
  CLASSIFICATIONS = {
    (0..24)  => "Extreme Fear",
    (25..44) => "Fear",
    (45..55) => "Neutral",
    (56..74) => "Greed",
    (75..100) => "Extreme Greed"
  }.freeze

  # A sentiment reading is a "today" number in the UI, so an old one must not
  # be served as current — CNN's index went dark and the last stored value
  # would otherwise have kept rendering as if it were fresh.
  FRESHNESS_WINDOW = 25.hours

  validates :index_type, presence: true, inclusion: { in: %w[crypto stocks] }
  validates :value, presence: true, numericality: { in: 0..100 }
  validates :classification, presence: true
  validates :source, presence: true
  validates :fetched_at, presence: true

  scope :crypto, -> { where(index_type: "crypto") }
  scope :stocks, -> { where(index_type: "stocks") }
  scope :recent, -> { order(fetched_at: :desc).limit(30) }
  scope :fresh, -> { where(fetched_at: FRESHNESS_WINDOW.ago..) }

  def self.latest_crypto = crypto.fresh.order(fetched_at: :desc).first
  def self.latest_stocks = stocks.fresh.order(fetched_at: :desc).first

  def stale?
    fetched_at < FRESHNESS_WINDOW.ago
  end

  def self.classify(value)
    CLASSIFICATIONS.find { |range, _| range.cover?(value) }&.last || "Neutral"
  end
end
