module MarketData
  module Domain
    # Pure stateless calculator for derived financial metrics.
    # Receives raw statement data hashes, returns metrics hash.
    # No DB reads, no I/O, no side effects.
    class FundamentalCalculator
    TTM_KEYS = %w[total_revenue gross_profit operating_income net_income
                  ebitda interest_expense research_and_development
                  operating_cashflow capital_expenditures dividend_payout].freeze

    class << self
      include SafeDecimal

      # Main entry point: latest annual statements → calculated metrics hash.
      def calculate(income_data:, balance_data:, cash_flow_data:, overview_metrics: {})
        {
          debt_to_equity: debt_to_equity(balance_data),
          current_ratio: current_ratio(balance_data),
          quick_ratio: quick_ratio(balance_data),
          net_margin: net_margin(income_data),
          operating_margin: operating_margin(income_data),
          gross_margin: gross_margin(income_data),
          interest_coverage: interest_coverage(income_data),
          free_cash_flow: free_cash_flow(cash_flow_data),
          fcf_yield: fcf_yield(cash_flow_data, overview_metrics),
          operating_cash_flow: operating_cash_flow(cash_flow_data),
          roe_calculated: roe(income_data, balance_data),
          roa_calculated: roa(income_data, balance_data)
        }.compact
      end

      # TTM: sum last 4 quarterly income/cash_flow reports.
      # Balance sheet uses latest snapshot (no summing needed).
      def calculate_ttm(quarterly_reports)
        return {} if quarterly_reports.blank? || quarterly_reports.size < 4

        last_four = quarterly_reports.first(4)
        summed = {}

        TTM_KEYS.each do |key|
          values = last_four.filter_map { |quarter| safe_decimal(quarter[key]) }
          summed[key] = values.sum if values.size == 4
        end

        summed
      end

      private

      # --- Health ---

      def debt_to_equity(balance)
        short_debt = safe_decimal(balance["short_term_debt"]) || BigDecimal("0")
        long_debt = safe_decimal(balance["long_term_debt"]) || BigDecimal("0")
        ratio(short_debt + long_debt, safe_decimal(balance["total_shareholder_equity"]))
      end

      def current_ratio(balance)
        ratio(safe_decimal(balance["total_current_assets"]),
              safe_decimal(balance["total_current_liabilities"]))
      end

      def quick_ratio(balance)
        assets = safe_decimal(balance["total_current_assets"])
        return nil unless assets

        inventory = safe_decimal(balance["inventory"]) || BigDecimal("0")
        ratio(assets - inventory, safe_decimal(balance["total_current_liabilities"]))
      end

      # --- Profitability ---

      def net_margin(income)
        ratio(safe_decimal(income["net_income"]), safe_decimal(income["total_revenue"]))
      end

      def operating_margin(income)
        ratio(safe_decimal(income["operating_income"]), safe_decimal(income["total_revenue"]))
      end

      def gross_margin(income)
        ratio(safe_decimal(income["gross_profit"]), safe_decimal(income["total_revenue"]))
      end

      def interest_coverage(income)
        ratio(safe_decimal(income["operating_income"]), safe_decimal(income["interest_expense"]))
      end

      # --- Cash Flow ---

      def free_cash_flow(cash_flow)
        operating = safe_decimal(cash_flow["operating_cashflow"])
        capex = safe_decimal(cash_flow["capital_expenditures"])
        return nil unless operating && capex
        operating - capex.abs
      end

      def operating_cash_flow(cash_flow)
        safe_decimal(cash_flow["operating_cashflow"])
      end

      def fcf_yield(cash_flow, overview)
        ratio(free_cash_flow(cash_flow), safe_decimal(overview["market_cap"] || overview[:market_cap]))
      end

      # --- Return Metrics ---

      def roe(income, balance)
        ratio(safe_decimal(income["net_income"]), safe_decimal(balance["total_shareholder_equity"]))
      end

      def roa(income, balance)
        ratio(safe_decimal(income["net_income"]), safe_decimal(balance["total_assets"]))
      end

      def ratio(numerator, denominator)
        return nil unless numerator && denominator&.nonzero?
        (numerator / denominator).round(4)
      end
    end
    end
  end
end
