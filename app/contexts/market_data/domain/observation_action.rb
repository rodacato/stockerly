module MarketData
  module Domain
    # ADR-013: this table is the whole allowance — a verb only ever comes from
    # a persisted observation, and widening it means writing a detector, not
    # editing a template. Exits are absent on purpose: returning to the middle
    # is not an action.
    module ObservationAction
      ACTIONS = {
        "rsi_oversold_entered"   => :buy,
        "bb_lower_breached"      => :buy,
        "ma200_crossed_above"    => :buy,
        "ma50_crossed_above"     => :buy,
        "rsi_overbought_entered" => :sell,
        "bb_upper_breached"      => :sell,
        "ma200_crossed_below"    => :sell,
        "ma50_crossed_below"     => :sell
      }.freeze

      ACTIONABLE_TYPES = ACTIONS.keys.freeze

      # @api public
      def self.for(observation_type)
        ACTIONS[observation_type.to_s]
      end
    end
  end
end
