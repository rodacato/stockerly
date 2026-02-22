class FxRate < ApplicationRecord
  validates :base_currency,  presence: true
  validates :quote_currency, presence: true
  validates :rate,           presence: true, numericality: { greater_than: 0 }
  validates :fetched_at,     presence: true

  validates :base_currency, uniqueness: { scope: :quote_currency }

  scope :latest, -> { order(fetched_at: :desc) }

  def self.convert(amount, from:, to:)
    return amount if from == to
    rate = find_by(base_currency: from, quote_currency: to)&.rate
    rate ? amount * rate : nil
  end

  def self.last_refresh
    maximum(:fetched_at)
  end
end
