module MarketData
  module Handlers
    class RecalculateFundamentalsOnStatementsSynced
      def self.call(event)
        asset_id = event.is_a?(Hash) ? event[:asset_id] : event.asset_id
        symbol   = event.is_a?(Hash) ? event[:symbol] : event.symbol

        asset = Asset.find_by(id: asset_id)
        return unless asset

        income = asset.financial_statements.income_statements.annual.recent.first
        balance = asset.financial_statements.balance_sheets.annual.recent.first
        cash_flow = asset.financial_statements.cash_flows.annual.recent.first

        return unless income && balance && cash_flow

        overview = asset.asset_fundamentals.overview.first

        metrics = Domain::FundamentalCalculator.calculate(
          income_data: income.data,
          balance_data: balance.data,
          cash_flow_data: cash_flow.data,
          overview_metrics: overview&.metrics || {}
        )

        quarterly_income = asset.financial_statements.income_statements.quarterly.recent.limit(4).map(&:data)
        quarterly_cf = asset.financial_statements.cash_flows.quarterly.recent.limit(4).map(&:data)

        ttm_income = Domain::FundamentalCalculator.calculate_ttm(quarterly_income)
        ttm_cf = Domain::FundamentalCalculator.calculate_ttm(quarterly_cf)

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
    end
  end
end
