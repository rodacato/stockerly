module MarketData
  module Queries
    # Public read API: the earnings dates falling inside a window. ADR-002:
    # Trading must not reach into `EarningsEvent` from outside MarketData.
    #
    # The window is the caller's, not this query's — how far ahead an earnings
    # date is worth announcing is a notification policy, and MarketData has no
    # opinion on it.
    class UpcomingEarnings
      def self.within(days:, from: Date.current)
        EarningsEvent
          .where(report_date: from..(from + days.days))
          .includes(:asset)
      end
    end
  end
end
