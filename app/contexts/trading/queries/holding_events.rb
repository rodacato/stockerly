module Trading
  module Queries
    # Public read API (ADR-031's 2026-10-22 amendment): what is coming for the
    # owner's holdings — maturities and earnings reports — as plain data.
    class HoldingEvents
      DAYS = Domain::MaturityWindow::DAYS

      def self.call(user: User.first)
        positions = user&.portfolio&.open_positions&.includes(:asset).to_a
        (maturities(positions) + earnings(positions)).sort_by { |event| [ event[:date], event[:symbol] ] }
      end

      def self.maturities(positions)
        positions.filter_map do |position|
          days = Domain::MaturityWindow.days_until(position)
          { kind: :maturity, symbol: position.asset.symbol, date: position.maturity_date, days: days } if days
        end
      end

      def self.earnings(positions)
        held = positions.map(&:asset_id)
        MarketData::Queries::UpcomingEarnings.within(days: DAYS).select { |event| held.include?(event.asset_id) }.map do |event|
          date = event.report_date.to_date
          { kind: :earnings, symbol: event.asset.symbol, date: date, days: (date - Date.current).to_i }
        end
      end

      private_class_method :maturities, :earnings
    end
  end
end
