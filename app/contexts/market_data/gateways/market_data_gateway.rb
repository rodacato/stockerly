module MarketData
  module Gateways
    # Interface (Output Port) for market data providers.
    # Concrete adapters: PolygonGateway (stocks), CoingeckoGateway (crypto), YahooFinanceGateway (BMV).
    class MarketDataGateway
      def fetch_price(_symbol)
        raise NotImplementedError, "#{self.class}#fetch_price not implemented"
      end

      def fetch_bulk_prices(_symbols)
        raise NotImplementedError, "#{self.class}#fetch_bulk_prices not implemented"
      end
    end
  end
end
