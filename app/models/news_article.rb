class NewsArticle < ApplicationRecord
  validates :title,        presence: true
  validates :source,       presence: true
  validates :published_at, presence: true

  scope :recent, -> { order(published_at: :desc).limit(10) }
  scope :for_ticker, ->(ticker) { where(related_ticker: ticker) if ticker.present? }
end
