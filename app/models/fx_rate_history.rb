# The daily FX store ADR-0009 chose. `fx_rates` holds one row per pair — the
# current rate — which is why a trade backdated to May was valued at today's
# rate. This one is keyed by date, so a historical figure can be honest.
class FxRateHistory < ApplicationRecord
  # What a reader needs to say where a rate came from without knowing the
  # series: the number, the date it is really for, and who produced it.
  Quote = Data.define(:rate, :rate_date, :source)

  validates :base_currency, :quote_currency, :rate_date, presence: true
  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :base_currency, uniqueness: { scope: [ :quote_currency, :rate_date ] }

  scope :for_pair, ->(base, quote) { where(base_currency: base.to_s.upcase, quote_currency: quote.to_s.upcase) }

  # The settlement series has a row for every calendar day, so the walk-back
  # only fires before the series starts or for a pair we do not collect.
  def self.quote_on(base:, quote:, date:)
    base = base.to_s.upcase
    quote = quote.to_s.upcase
    return Quote.new(rate: BigDecimal(1), rate_date: date, source: "identity") if base == quote

    forward = for_pair(base, quote).where(rate_date: ..date).order(rate_date: :desc).first
    return Quote.new(rate: forward.rate, rate_date: forward.rate_date, source: forward.source) if forward

    inverse = for_pair(quote, base).where(rate_date: ..date).order(rate_date: :desc).first
    return nil unless inverse&.rate&.positive?

    Quote.new(rate: 1 / inverse.rate, rate_date: inverse.rate_date, source: inverse.source)
  end

  def self.rate_on(base:, quote:, date:)
    quote_on(base: base, quote: quote, date: date)&.rate
  end

  def self.record(base:, quote:, date:, rate:, source: "unknown")
    find_or_initialize_by(
      base_currency: base.to_s.upcase,
      quote_currency: quote.to_s.upcase,
      rate_date: date
    ).tap { |row| row.update!(rate: rate, source: source) }
  end

  # Seeding thirty-five years of Banxico one row at a time is two queries per
  # row; the unique index already states the conflict, so let Postgres do it.
  def self.record_all(rows)
    return 0 if rows.empty?

    upsert_all(
      rows,
      unique_by: [ :base_currency, :quote_currency, :rate_date ],
      update_only: [ :rate, :source ],
      record_timestamps: true
    ).count
  end
end
