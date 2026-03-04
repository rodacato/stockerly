class NewsArticle < ApplicationRecord
  validates :title,        presence: true
  validates :source,       presence: true
  validates :published_at, presence: true
  validates :url,          uniqueness: true, allow_blank: true

  scope :recent, -> { order(published_at: :desc).limit(10) }
  scope :unanalyzed, -> { where(sentiment: nil) }
  scope :with_sentiment, -> { where.not(sentiment: nil) }
  scope :bullish, -> { where(sentiment: "bullish") }
  scope :bearish, -> { where(sentiment: "bearish") }
  scope :for_ticker, ->(ticker) { where(related_ticker: ticker) if ticker.present? }
  scope :for_tickers, ->(tickers) { where(related_ticker: tickers) if tickers.present? }
  scope :for_source, ->(source) { where(source: source) if source.present? }
  scope :published_after, ->(time) { where("published_at >= ?", time) if time.present? }
end
