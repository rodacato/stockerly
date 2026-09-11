module MarketData
  module Handlers
    class RecalculateFundamentalsOnStatementsSynced
      INCOME_ANCHOR = "total_revenue".freeze
      CASH_FLOW_ANCHOR = "operating_cashflow".freeze

      def self.call(event)
        asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
        symbol   = event.is_a?(Hash) ? event[:symbol] : event.symbol

        asset = Asset.find_by(id: asset_id)
        return unless asset

        income = asset.financial_statements.income_statements.annual.recent.first
        balance = asset.financial_statements.balance_sheets.recent.first
        cash_flow = asset.financial_statements.cash_flows.annual.recent.first

        return unless income && balance && cash_flow

        overview = asset.asset_fundamentals.overview.first

        quarterly_income = reported_quarters(asset.financial_statements.income_statements, anchor: INCOME_ANCHOR)
        quarterly_cf = reported_quarters(asset.financial_statements.cash_flows, anchor: CASH_FLOW_ANCHOR)

        ttm_income = Domain::FundamentalCalculator.calculate_ttm(quarterly_income)
        ttm_cf = Domain::FundamentalCalculator.calculate_ttm(quarterly_cf)

        metrics = Domain::FundamentalCalculator.calculate(
          income_data: trailing_or_annual(ttm_income, income.data, anchor: INCOME_ANCHOR),
          balance_data: balance.data,
          cash_flow_data: trailing_or_annual(ttm_cf, cash_flow.data, anchor: CASH_FLOW_ANCHOR),
          overview_metrics: overview&.metrics || {}
        )

        metrics.merge!(ttm_income.transform_keys { |k| "ttm_#{k}" }) if ttm_income.present?
        metrics.merge!(ttm_cf.transform_keys { |k| "ttm_#{k}" }) if ttm_cf.present?

        fundamental = AssetFundamental.find_or_initialize_by(asset: asset, period_label: "CALCULATED")
        fundamental.update!(
          metrics: metrics,
          source: "calculated",
          calculated_at: Time.current
        )

        EventBus.publish(Events::AssetFundamentalsUpdated.new(
          asset_id: asset.id,
          symbol: symbol,
          source: "calculated_from_statements"
        ))
      end

      # All four quarters or the annual statement — never mixed key by key,
      # which would divide one window by another (D116).
      def self.trailing_or_annual(ttm, annual, anchor:)
        ttm.key?(anchor) ? ttm : annual
      end
      private_class_method :trailing_or_annual

      # Earnings land before the statements, so the newest quarter can arrive as
      # EPS alone. The four start at the newest one with the anchor, never past a gap.
      def self.reported_quarters(statements, anchor:)
        statements.quarterly.recent.limit(5).map(&:data).drop_while { |data| data[anchor].blank? }.first(4)
      end
      private_class_method :reported_quarters
    end
  end
end
