module Assistant
  module Capabilities
    # The closed list of what the assistant may read (ADR-031 §2). A name not
    # listed cannot run, whoever asks for it — the planner included. One per
    # question: it remembers each asset's brief so capabilities share one read.
    class Registry
      CAPABILITIES = [ GlossaryDefine, AssetQuote, AssetRange, AssetIndicators, AssetFundamentals, AssetObservations, AssetNews,
                       AssetEarnings, MarketPulse, ExchangeRate, CetesCurve, PortfolioPositions, PortfolioEvents, RecentSignals ]
                       .index_by(&:name_in_registry).freeze

      def self.names = CAPABILITIES.keys

      # With the switch off a holdings read is not listed, so it reads as unknown to everyone.
      def self.available(holdings:) = holdings ? CAPABILITIES : CAPABILITIES.reject { |_, capability| capability.holdings? }

      def initialize(holdings: false)
        @holdings = holdings
        @capabilities = self.class.available(holdings: holdings)
      end

      def holdings? = @holdings

      def call(name, **input)
        capability = @capabilities[name.to_s]
        return Result.failed(name, :unknown) unless capability
        return Result.failed(name, :invalid_input) unless capability.accepts?(input)

        cards = capability.new(self).cards(**input)
        return Result.failed(name, :no_data) if cards.empty?

        Result.ok(name, cards.map { |card| card.within(capability::MAX_CHARS) })
      rescue StandardError => error
        Rails.logger.warn("[assistant] #{name} failed: #{error.class}: #{error.message}")
        Result.failed(name, :error)
      end

      def cards(steps) = steps.map { |name, input| call(name, **input) }.select(&:ok?).flat_map(&:cards)

      def brief(symbol)
        key = symbol.to_s.strip.upcase
        (@briefs ||= {}).fetch(key) { @briefs[key] = MarketData::Queries::AssetBrief.call(symbol: key) }
      end
    end
  end
end
