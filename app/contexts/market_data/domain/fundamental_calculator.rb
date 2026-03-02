module MarketData
  # Pure stateless calculator for derived financial metrics.
  # Receives raw statement data hashes, returns metrics hash.
  # No DB reads, no I/O, no side effects.
  class FundamentalCalculator
    class << self
      # Main entry point: latest annual statements → calculated metrics hash.
      def calculate(income_data:, balance_data:, cash_flow_data:, overview_metrics: {})
        metrics = {}

        # Health (from balance sheet)
        metrics[:debt_to_equity] = debt_to_equity(balance_data)
        metrics[:current_ratio] = current_ratio(balance_data)
        metrics[:quick_ratio] = quick_ratio(balance_data)

        # Profitability (from income statement)
        metrics[:net_margin] = net_margin(income_data)
        metrics[:operating_margin] = operating_margin(income_data)
        metrics[:gross_margin] = gross_margin(income_data)
        metrics[:interest_coverage] = interest_coverage(income_data)

        # Cash flow
        metrics[:free_cash_flow] = free_cash_flow(cash_flow_data)
        metrics[:fcf_yield] = fcf_yield(cash_flow_data, overview_metrics)
        metrics[:operating_cash_flow] = safe_decimal(cash_flow_data["operating_cashflow"])

        # Return metrics (income + balance)
        metrics[:roe_calculated] = roe(income_data, balance_data)
        metrics[:roa_calculated] = roa(income_data, balance_data)

        metrics.compact
      end

      # TTM: sum last 4 quarterly income/cash_flow reports.
      # Balance sheet uses latest snapshot (no summing needed).
      def calculate_ttm(quarterly_reports)
        return {} if quarterly_reports.blank? || quarterly_reports.size < 4

        last_four = quarterly_reports.first(4)
        summed = {}

        numeric_keys = %w[total_revenue gross_profit operating_income net_income
                          ebitda interest_expense research_and_development
                          operating_cashflow capital_expenditures dividend_payout]

        numeric_keys.each do |key|
          values = last_four.map { |q| safe_decimal(q[key]) }.compact
          summed[key] = values.sum if values.size == 4
        end

        summed
      end

      # CAGR: (end_value / start_value)^(1/years) - 1
      def cagr(end_value, start_value, years)
        return nil if end_value.nil? || start_value.nil? || years.nil? || years.zero?
        return nil if start_value.zero? || start_value.negative?
        return nil if end_value.negative?

        ((end_value.to_d / start_value.to_d) ** (1.0 / years) - 1).round(4)
      rescue Math::DomainError
        nil
      end

      private

      # --- Health ---

      def debt_to_equity(balance)
        short_debt = safe_decimal(balance["short_term_debt"]) || BigDecimal("0")
        long_debt = safe_decimal(balance["long_term_debt"]) || BigDecimal("0")
        equity = safe_decimal(balance["total_shareholder_equity"])
        return nil unless equity&.nonzero?

        ((short_debt + long_debt) / equity).round(4)
      end

      def current_ratio(balance)
        assets = safe_decimal(balance["total_current_assets"])
        liabilities = safe_decimal(balance["total_current_liabilities"])
        return nil unless assets && liabilities&.nonzero?
        (assets / liabilities).round(4)
      end

      def quick_ratio(balance)
        assets = safe_decimal(balance["total_current_assets"])
        inventory = safe_decimal(balance["inventory"]) || BigDecimal("0")
        liabilities = safe_decimal(balance["total_current_liabilities"])
        return nil unless assets && liabilities&.nonzero?
        ((assets - inventory) / liabilities).round(4)
      end

      # --- Profitability ---

      def net_margin(income)
        net = safe_decimal(income["net_income"])
        revenue = safe_decimal(income["total_revenue"])
        return nil unless net && revenue&.nonzero?
        (net / revenue).round(4)
      end

      def operating_margin(income)
        operating = safe_decimal(income["operating_income"])
        revenue = safe_decimal(income["total_revenue"])
        return nil unless operating && revenue&.nonzero?
        (operating / revenue).round(4)
      end

      def gross_margin(income)
        gross = safe_decimal(income["gross_profit"])
        revenue = safe_decimal(income["total_revenue"])
        return nil unless gross && revenue&.nonzero?
        (gross / revenue).round(4)
      end

      def interest_coverage(income)
        operating = safe_decimal(income["operating_income"])
        interest = safe_decimal(income["interest_expense"])
        return nil unless operating && interest&.nonzero?
        (operating / interest).round(4)
      end

      # --- Cash Flow ---

      def free_cash_flow(cash_flow)
        operating = safe_decimal(cash_flow["operating_cashflow"])
        capex = safe_decimal(cash_flow["capital_expenditures"])
        return nil unless operating && capex
        operating - capex.abs
      end

      def fcf_yield(cash_flow, overview)
        fcf = free_cash_flow(cash_flow)
        market_cap = safe_decimal(overview["market_cap"] || overview[:market_cap])
        return nil unless fcf && market_cap&.nonzero?
        (fcf / market_cap).round(4)
      end

      # --- Return Metrics ---

      def roe(income, balance)
        net = safe_decimal(income["net_income"])
        equity = safe_decimal(balance["total_shareholder_equity"])
        return nil unless net && equity&.nonzero?
        (net / equity).round(4)
      end

      def roa(income, balance)
        net = safe_decimal(income["net_income"])
        assets = safe_decimal(balance["total_assets"])
        return nil unless net && assets&.nonzero?
        (net / assets).round(4)
      end

      def safe_decimal(value)
        return nil if value.blank? || value == "None" || value == "-"
        BigDecimal(value.to_s)
      rescue ArgumentError
        nil
      end
    end
  end
end
