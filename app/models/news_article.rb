class NewsArticle < ApplicationRecord
  validates :title,        presence: true
  validates :source,       presence: true
  validates :published_at, presence: true

  scope :recent, -> { order(published_at: :desc).limit(10) }
  scope :for_ticker, ->(ticker) { where(related_ticker: ticker) if ticker.present? }
  scope :for_source, ->(source) { where(source: source) if source.present? }
  scope :published_after, ->(time) { where("published_at >= ?", time) if time.present? }
end
