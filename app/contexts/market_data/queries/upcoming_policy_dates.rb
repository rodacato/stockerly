module MarketData
  module Queries
    # Public read API: central-bank decisions (Fed, Banxico) due in the next days.
    #
    # ADR-002: Trading asks this rather than reaching into the Discover calendar.
    # Empty past the calendar's horizon, which is "nothing known", not "nothing due".
    class UpcomingPolicyDates
      def self.within(days:, today: Date.current)
        Discover::PolicyCalendar.within(days: days, today: today)
      end
    end
  end
end
