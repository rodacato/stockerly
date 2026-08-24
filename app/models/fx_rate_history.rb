# The daily FX store ADR-0009 chose. `fx_rates` holds one row per pair — the
# current rate — which is why a trade backdated to May was valued at today's
# rate. This one is keyed by date, so a historical figure can be honest.
class FxRateHistory < ApplicationRecord
  validates :base_currency, :quote_currency, :rate_date, presence: true
  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :base_currency, uniqueness: { scope: [ :quote_currency, :rate_date ] }

  scope :for_pair, ->(base, quote) { where(base_currency: base.to_s.upcase, quote_currency: quote.to_s.upcase) }

  # The rate for a date, or the most recent one before it. Markets close on
  # weekends and Mexican holidays, so an exact-date lookup would return nothing
  # for a trade executed on a Saturday — the honest answer there is Friday's
  # fix, not today's.
  def self.rate_on(base:, quote:, date:)
    base = base.to_s.upcase
    quote = quote.to_s.upcase
    return BigDecimal(1) if base == quote

    forward = for_pair(base, quote).where(rate_date: ..date).order(rate_date: :desc).first
    return forward.rate if forward

    inverse = for_pair(quote, base).where(rate_date: ..date).order(rate_date: :desc).first
    return (1 / inverse.rate) if inverse&.rate&.positive?

    nil
  end

  def self.record(base:, quote:, date:, rate:, source: "unknown")
    find_or_initialize_by(
      base_currency: base.to_s.upcase,
      quote_currency: quote.to_s.upcase,
      rate_date: date
    ).tap { |row| row.update!(rate: rate, source: source) }
  end
end
