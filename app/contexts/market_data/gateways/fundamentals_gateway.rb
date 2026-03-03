module MarketData
  module Gateways
    # Base class defining the interface for fundamental data providers.
    # Concrete implementations: AlphaVantageGateway (Phase 10.0).
    # Designed for provider swap (FMP, Polygon) without touching domain.
    class FundamentalsGateway
      include Dry::Monads[:result]

      def fetch_overview(symbol)
        raise NotImplementedError
      end

      def fetch_income_statement(symbol)
        raise NotImplementedError
      end

      def fetch_balance_sheet(symbol)
        raise NotImplementedError
      end

      def fetch_cash_flow(symbol)
        raise NotImplementedError
      end
    end
  end
end
