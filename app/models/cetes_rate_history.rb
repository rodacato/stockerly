# The auction yields the Consolidado's benchmark reinvests against. Keyed by
# date the way FxRateHistory is, and for the same reason: a comparison over a
# period needs the rates of that period, not today's.
class CetesRateHistory < ApplicationRecord
  TERMS = %w[28 91 182 364].freeze

  validates :term, presence: true, inclusion: { in: TERMS }
  validates :auction_date, presence: true
  validates :yield_rate, presence: true, numericality: { greater_than: 0 }
  validates :term, uniqueness: { scope: :auction_date }

  scope :for_term, ->(term) { where(term: term.to_s) }

  # The rate in force on a date: the most recent auction on or before it.
  # Auctions are weekly, so an exact-date lookup would miss six days in seven.
  def self.rate_on(term:, date:)
    for_term(term).where(auction_date: ..date).order(auction_date: :desc).first&.yield_rate
  end

  def self.record(term:, date:, rate:, source: "banxico")
    find_or_initialize_by(term: term.to_s, auction_date: date)
      .tap { |row| row.update!(yield_rate: rate, source: source) }
  end
end
