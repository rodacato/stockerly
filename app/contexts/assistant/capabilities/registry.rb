module Assistant
  module Capabilities
    # The closed list of what the assistant may read (ADR-031 §2). A name not
    # listed cannot run, whoever asks for it — the planner included. One per
    # question: it remembers each asset's brief so capabilities share one read.
    class Registry
      CAPABILITIES = [ GlossaryDefine, AssetQuote, AssetRange, AssetIndicators, AssetFundamentals, AssetObservations, AssetNews ]
                       .index_by(&:name_in_registry).freeze

      def self.names = CAPABILITIES.keys

      def call(name, **input)
        capability = CAPABILITIES[name.to_s]
        return Result.failed(name, :unknown) unless capability
        return Result.failed(name, :invalid_input) unless capability.accepts?(input)

        cards = capability.new(self).cards(**input)
        return Result.failed(name, :no_data) if cards.empty?

        Result.ok(name, cards.map { |card| card.within(capability::MAX_CHARS) })
      rescue StandardError => error
        Rails.logger.warn("[assistant] #{name} failed: #{error.class}: #{error.message}")
        Result.failed(name, :error)
      end

      def brief(symbol)
        key = symbol.to_s.strip.upcase
        (@briefs ||= {}).fetch(key) { @briefs[key] = MarketData::Queries::AssetBrief.call(symbol: key) }
      end
    end
  end
end
