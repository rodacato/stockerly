module Trading
  module UseCases
    # Public read API: the symbols the user currently holds.
    #
    # Exists for Descubrir's exposure chip. D31 clause 5 forbids that screen
    # *writing* an Asset, not reading what is already owned — but ADR-002 pairs
    # Trading as MarketData's customer, not the other way round, so the reading
    # is done by the screen through this door rather than by MarketData::Discover
    # reaching into positions.
    class OwnedSymbols < SimpleUseCase
      def call(user:)
        portfolio = user&.portfolio
        return [] if portfolio.nil?

        portfolio.open_positions.includes(:asset).filter_map { |position| position.asset&.symbol }.uniq
      end
    end
  end
end
