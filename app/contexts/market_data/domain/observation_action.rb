module MarketData
  module Domain
    # ADR-013: an action verb may reach the user only as a deterministic
    # function of a persisted TechnicalObservation. This table is that
    # function, and the only place it exists. Widening it means adding an
    # observation type and the detector that populates it — never a copy
    # decision inside a template.
    #
    # Types absent from the table produce no verb. Exits (leaving oversold,
    # leaving overbought) are deliberately absent: they describe a return to
    # the middle, which is not an action.
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
