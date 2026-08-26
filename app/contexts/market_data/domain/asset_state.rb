module MarketData
  module Domain
    # ADR-014: the closed catalogue. A state is a pure function of persisted
    # observations, and each state maps to phrase keys — never to composed
    # prose. The es-MX text lives in the locale file (ADR-011); what lives here
    # is which phrase a state is entitled to, which is the part that must not
    # be decided in a template.
    #
    # The most recent observation wins, so an exit returns the asset to
    # neutral without a special case: leaving overbought is its own event.
    module AssetState
      STATES = %i[stretched oversold neutral].freeze

      BY_OBSERVATION = {
        "rsi_overbought_entered" => :stretched,
        "bb_upper_breached"      => :stretched,
        "rsi_oversold_entered"   => :oversold,
        "bb_lower_breached"      => :oversold,
        "rsi_overbought_exited"  => :neutral,
        "rsi_oversold_exited"    => :neutral
      }.freeze

      # Moving-average crossings say nothing about being stretched — they are
      # trend, not extension — so they are deliberately absent and leave the
      # state to whatever the last RSI or Bollinger event said.
      TREND_ONLY = %w[
        ma200_crossed_above ma200_crossed_below ma50_crossed_above ma50_crossed_below
      ].freeze

      # @api public
      def self.for(observations)
        latest = Array(observations)
                 .reject { |o| TREND_ONLY.include?(o.observation_type) }
                 .max_by(&:observed_at)
        return :neutral if latest.nil?

        BY_OBSERVATION.fetch(latest.observation_type, :neutral)
      end

      # The observation the state came from, so the reading can stay on screen
      # beside the phrase (ADR-014, Renata's condition).
      # @api public
      def self.source(observations)
        Array(observations)
          .reject { |o| TREND_ONLY.include?(o.observation_type) }
          .select { |o| BY_OBSERVATION.key?(o.observation_type) }
          .max_by(&:observed_at)
      end

      # The trend events `for` deliberately drops. They are not extension, so
      # they must not move the state — but they are the confluence semaphore's
      # third light, and nothing rendered them before.
      # @api public
      def self.trend(observations)
        Array(observations)
          .select { |o| TREND_ONLY.include?(o.observation_type) }
          .max_by(&:observed_at)
      end

      # :bullish when the last crossing was upward, :bearish when downward.
      # @api public
      def self.trend_direction(observation)
        return nil if observation.nil?

        observation.observation_type.end_with?("above") ? :bullish : :bearish
      end

      # @api public
      def self.phrase_key(state, holding:)
        state = :neutral unless STATES.include?(state)
        "market.estado.#{state}.#{holding ? "holding" : "watching"}"
      end

      # @api public
      def self.label_key(state)
        state = :neutral unless STATES.include?(state)
        "market.estado.#{state}.label"
      end
    end
  end
end
