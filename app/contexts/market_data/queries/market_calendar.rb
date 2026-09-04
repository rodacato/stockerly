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
    end
  end
end
