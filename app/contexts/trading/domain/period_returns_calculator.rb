module Trading
  module Domain
    class PeriodReturnsCalculator
      PERIODS = {
        "1D" => 1.day,
        "1W" => 1.week,
        "1M" => 1.month,
        "3M" => 3.months,
        "6M" => 6.months,
        "1Y" => 1.year
      }.freeze

      def initialize(portfolio)
        @portfolio = portfolio
      end

      def calculate
        current_value = @portfolio.total_value
        snapshots = @portfolio.snapshots.order(:date)
        return empty_results if snapshots.empty?

        results = {}

        PERIODS.each do |label, duration|
          target_date = duration.ago.to_date
          snapshot = nearest_snapshot(snapshots, target_date)
          results[label] = compute_return(current_value, snapshot)
        end

        results["YTD"] = compute_return(current_value, nearest_snapshot(snapshots, Date.current.beginning_of_year))
        results["ALL"] = compute_return(current_value, snapshots.first)

        results
      end

      def chart_data(period: "1M")
        duration = PERIODS[period] || 1.month
        start_date = duration.ago.to_date

        @portfolio.snapshots
          .where("date >= ?", start_date)
          .order(:date)
          .pluck(:date, :total_value)
          .map { |date, value| { date: date, value: value.to_f } }
      end

      private

      def nearest_snapshot(snapshots, target_date)
        snapshots.detect { |s| s.date >= target_date } || snapshots.last
      end

      def compute_return(current_value, snapshot)
        return GainLoss.new(absolute: 0.0, percent: 0.0) unless snapshot

        base = snapshot.total_value.to_f
        diff = current_value.to_f - base
        percent = base.positive? ? (diff / base * 100) : 0.0

        GainLoss.new(absolute: diff.round(2), percent: percent.round(2))
      end

      def empty_results
        empty = GainLoss.new(absolute: 0.0, percent: 0.0)
        (PERIODS.keys + %w[YTD ALL]).index_with { empty }
      end
    end
  end
end
