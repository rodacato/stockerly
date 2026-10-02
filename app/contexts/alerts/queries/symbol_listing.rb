module Alerts
  module Queries
    # Whether the catalogue still answers to the symbol a rule was written
    # against. Asset reads stay shared (ADR-024); the answer crosses as plain
    # data so callers never hold an Asset.
    class SymbolListing
      def self.call(symbol:)
        symbol = symbol.to_s.upcase
        return { state: :listed } if Asset.exists?(symbol: symbol)

        current = Asset.where("former_symbols && ARRAY[?]::varchar[]", [ symbol ]).pick(:symbol)
        current ? { state: :renamed, current_symbol: current } : { state: :missing }
      end
    end
  end
end
