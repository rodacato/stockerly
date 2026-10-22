module MarketData
  module Queries
    # Internal to this context: the ADR-031 queries resolve a symbol the same way,
    # current or former. It returns a record, so it is not part of the read API.
    module AssetLookup
      def self.by_symbol(symbol)
        symbol = symbol.to_s.strip.upcase
        return nil if symbol.empty?

        Asset.find_by(symbol: symbol) ||
          Asset.find_by("former_symbols && ARRAY[?]::varchar[]", [ symbol ])
      end
    end
  end
end
