# Calculates portfolio risk metrics from a series of daily snapshots.
# Requires at least 31 snapshots (30 daily returns) for meaningful results.
#
# Input:
#   snapshots: array of objects responding to #date, #total_value, #invested_value
#   risk_free_rate: annual rate as decimal (e.g., 0.1025 for 10.25%)
# Output:
#   RiskMetrics value object
module Trading
  module Domain
    class PortfolioRiskCalculator
      MINIMUM_SNAPSHOTS = 31
      TRADING_DAYS_PER_YEAR = 252

      def initialize(snapshots:, risk_free_rate: nil)
        @snapshots = snapshots.sort_by(&:date)
        @risk_free_rate = risk_free_rate || default_risk_free_rate
      end

      def calculate
        return insufficient_data_result if @snapshots.size < MINIMUM_SNAPSHOTS

        daily_returns = compute_daily_returns
        return insufficient_data_result if daily_returns.empty?

        vol = annualized_volatility(daily_returns)
        sharpe = compute_sharpe(daily_returns, vol)
        drawdown = compute_max_drawdown(daily_returns)

        RiskMetrics.new(
          volatility: vol.round(4),
          sharpe_ratio: sharpe.round(4),
          max_drawdown: drawdown.round(4),
          has_sufficient_data: true
        )
      end

      private

      def compute_daily_returns
        @snapshots.each_cons(2).map do |prev, curr|
          v_start = prev.total_value.to_f
          v_end = curr.total_value.to_f
          cash_flow = detect_cash_flow(prev, curr)

          next 0.0 if v_start.zero?

          (v_end - v_start - cash_flow) / v_start
        end
      end

      def detect_cash_flow(prev_snapshot, curr_snapshot)
        return 0.0 unless prev_snapshot.respond_to?(:invested_value) && curr_snapshot.respond_to?(:invested_value)
        return 0.0 if prev_snapshot.invested_value.nil? || curr_snapshot.invested_value.nil?

        curr_snapshot.invested_value.to_f - prev_snapshot.invested_value.to_f
      end

      def annualized_volatility(daily_returns)
        mean = daily_returns.sum / daily_returns.size.to_f
        variance = daily_returns.sum { |r| (r - mean)**2 } / daily_returns.size.to_f
        daily_std = Math.sqrt(variance)

        daily_std * Math.sqrt(TRADING_DAYS_PER_YEAR)
      end

      def compute_sharpe(daily_returns, annualized_vol)
        return 0.0 if annualized_vol.zero?

        mean_daily = daily_returns.sum / daily_returns.size.to_f
        annualized_return = mean_daily * TRADING_DAYS_PER_YEAR

        (annualized_return - @risk_free_rate) / annualized_vol
      end

      def compute_max_drawdown(daily_returns)
        cumulative = 1.0
        peak = 1.0
        max_dd = 0.0

        daily_returns.each do |r|
          cumulative *= (1 + r)
          peak = cumulative if cumulative > peak
          drawdown = (peak - cumulative) / peak
          max_dd = drawdown if drawdown > max_dd
        end

        max_dd
      end

      def default_risk_free_rate
        cetes = Asset.find_by(symbol: "CETES_28D")
        rate = cetes&.yield_rate
        rate.present? ? rate.to_f / 100.0 : 0.0
      end

      def insufficient_data_result
        RiskMetrics.new(
          volatility: 0.0,
          sharpe_ratio: 0.0,
          max_drawdown: 0.0,
          has_sufficient_data: false
        )
      end
    end
  end
end
