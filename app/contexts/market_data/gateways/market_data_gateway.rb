module MarketData
  module Gateways
    # Interface (Output Port) for market data providers.
    # Concrete adapters: AlpacaGateway (US history), FinnhubGateway (US quotes),
    # DataBursatilGateway (BMV), CoingeckoGateway (crypto), YfinanceGateway (indices).
    class MarketDataGateway
      # Provenance recorded on every row this gateway produces. Sub-provider
      # granularity matters: Alpaca's sip and iex feeds are byte-identical in
      # shape, and DataBursatil quotes BMV and BIVA at different prices, so the
      # vendor name alone would lose the distinction that decides the number.
      def self.source_id
        const_defined?(:PROVIDER) ? const_get(:PROVIDER) : name
      end

      # How far back this provider will serve daily history, in days, or nil for
      # no limit of its own. A caller that asks past it does not get a shorter
      # answer — CoinGecko's public tier refuses the whole request with a 401 —
      # so the limit has to be known before the call, not discovered by it.
      def self.max_history_days = nil

      delegate :source_id, to: :class

      def fetch_price(_symbol)
        raise NotImplementedError, "#{self.class}#fetch_price not implemented"
      end

      def fetch_bulk_prices(_symbols)
        raise NotImplementedError, "#{self.class}#fetch_bulk_prices not implemented"
      end
    end
  end
end
