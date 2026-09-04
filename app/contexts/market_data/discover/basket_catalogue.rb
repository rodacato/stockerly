module MarketData
  module Discover
    # The 17 baskets Olas ranks, read from config/discover_baskets.yml (D31).
    #
    # No table and no Asset row: clause 5 of the disposability contract is that
    # a discovered symbol never becomes an Asset, because that would put it on
    # D9's sync ladder and the screen would stop being throwaway.
    class BasketCatalogue
      Basket = Data.define(:symbol, :name, :group, :referents)

      PATH = Rails.root.join("config/discover_baskets.yml")

      class << self
        def all
          baskets
        end

        def baseline
          data["baseline"]
        end

        # Every symbol the warm job has to fetch: the baskets plus the ruler
        # they are measured against, in one batch.
        def symbols
          baskets.map(&:symbol) + [ baseline ]
        end

        def reload!
          @data = nil
        end

        private

        def baskets
          (data["baskets"] || []).map do |row|
            Basket.new(symbol: row["symbol"], name: row["name"],
                       group: row["group"], referents: Array(row["referents"]))
          end
        end

        def data
          @data ||= YAML.safe_load_file(PATH) || {}
        end
      end
    end
  end
end
