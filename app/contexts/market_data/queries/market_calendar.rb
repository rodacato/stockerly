module MarketData
  module Queries
    # Public read API for the trading calendar. ADR-002: Alerts must not reach
    # into `MarketHoliday` from outside MarketData.
    class MarketCalendar
      # The holiday itself, because a caller that announces one needs its name.
      def self.holiday_on(market:, date:)
        MarketHoliday.find_by(market: market, date: date)
      end

      def self.holiday?(market:, date:)
        MarketHoliday.holiday?(market: market, date: date)
      end

      # Every closure one market observes in one year, in a single read. An
      # empty result means the calendar does not reach that year at all, which
      # is a different fact from "that year had no holidays" — callers decide
      # which way to fail, and MarketHours documents its choice.
      def self.dates_in_year(market:, year:)
        MarketHoliday.where(market: market, date: Date.new(year, 1, 1)..Date.new(year, 12, 31)).pluck(:date)
      end

      # How far the seeded calendar reaches for one market, or nil when it
      # holds nothing at all.
      def self.covered_through(market:)
        MarketHoliday.where(market: market).maximum(:date)
      end
    end
  end
end
