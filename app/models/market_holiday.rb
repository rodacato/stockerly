class MarketHoliday < ApplicationRecord
  enum :market, { BMV: 0, Banxico: 1, NYSE: 2, NASDAQ: 3 }

  validates :date, presence: true, uniqueness: { scope: :market }
  validates :name, presence: true

  scope :upcoming, -> { where("date >= ?", Date.current).order(:date) }

  # `next_business_day(market: ..., from: ...)` — first weekday on/after `from`
  # that is not a holiday for the given market. Used by the CETE auction
  # evaluator to walk forward when a Tuesday lands on a Banxico holiday.
  def self.next_business_day(market:, from: Date.current)
    candidate = from
    until weekday?(candidate) && !holiday?(market: market, date: candidate)
      candidate += 1
    end
    candidate
  end

  def self.holiday?(market:, date:)
    where(market: market, date: date).exists?
  end

  def self.weekday?(date)
    (1..5).cover?(date.wday)
  end
end
