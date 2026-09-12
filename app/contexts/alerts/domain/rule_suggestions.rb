module Alerts
  module Domain
    # Candidate rules derived from what the owner already holds, for someone who
    # does not know which indicator to watch. Returns the SHAPE of a rule and
    # never its wording: the view names it, so the phrases stay in one catalogue
    # (ADR-014) and this stays a pure function over holdings.
    class RuleSuggestions
      Suggestion = Struct.new(:condition, :asset_symbol, :threshold_value, :window_days, :shares, keyword_init: true)

      DAY_MOVE_PERCENT = 5
      RSI_OVERBOUGHT = 70
      CETE_WINDOW_DAYS = 3
      LIMIT = 3

      TECHNICAL_TYPES = %w[stock etf crypto].freeze

      def self.call(holdings:, existing_rules: [])
        new(holdings, existing_rules).call
      end

      def initialize(holdings, existing_rules)
        @holdings = Array(holdings)
        @taken = Array(existing_rules).map { |rule| key(rule[:condition], rule[:asset_symbol]) }
      end

      def call
        [ day_move, rsi_stretch, cete_maturity ].compact.reject { |s| taken?(s) }.first(LIMIT)
      end

      private

      attr_reader :holdings, :taken

      # The position that moves the portfolio most is the one worth a
      # day-move rule: a 5% swing there is felt, the same swing on a sliver is not.
      def day_move
        asset = by_value(TECHNICAL_TYPES).first
        return unless asset

        Suggestion.new(condition: "day_change_percent", asset_symbol: asset[:symbol],
                       threshold_value: DAY_MOVE_PERCENT, shares: asset[:shares])
      end

      # A different holding than the day-move one, so the empty state teaches two
      # indicators instead of stacking two rules on one symbol.
      def rsi_stretch
        candidates = by_value(TECHNICAL_TYPES)
        asset = candidates[1] || candidates.first
        return unless asset

        Suggestion.new(condition: "rsi_overbought", asset_symbol: asset[:symbol],
                       threshold_value: RSI_OVERBOUGHT, shares: asset[:shares])
      end

      def cete_maturity
        asset = holdings.find { |h| h[:asset_type].to_s == "fixed_income" }
        return unless asset

        Suggestion.new(condition: "cete_auction", asset_symbol: asset[:symbol],
                       window_days: CETE_WINDOW_DAYS, shares: asset[:shares])
      end

      def by_value(types)
        holdings.select { |h| types.include?(h[:asset_type].to_s) }
                .sort_by { |h| -h[:market_value].to_f }
      end

      def taken?(suggestion)
        taken.include?(key(suggestion.condition, suggestion.asset_symbol))
      end

      def key(condition, symbol)
        [ condition.to_s, symbol.to_s.upcase ]
      end
    end
  end
end
