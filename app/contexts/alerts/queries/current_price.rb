module Alerts
  module Queries
    # The last price the catalogue holds for a symbol, or nil. Asset reads stay
    # shared (ADR-024); the number crosses alone so callers never hold an Asset.
    class CurrentPrice
      def self.call(symbol:)
        Asset.where(symbol: symbol.to_s.upcase).pick(:current_price)
      end
    end
  end
end
