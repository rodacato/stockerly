module MarketData
  module Domain
    # ADR-013: this table is the whole allowance — a verb only ever comes from
    # a persisted observation, and widening it means writing a detector, not
    # editing a template. Exits are absent on purpose: returning to the middle
    # is not an action.
    #
    # D127: each verb travels with the move its phrase states, which the arrow
    # draws, and the reading it follows — crossings follow the trend, RSI and
    # Bollinger bet on a reversal — so a row can never say one and draw another.
    module ObservationAction
      Reading = Data.define(:action, :move, :logic)

      READINGS = {
        "rsi_oversold_entered"   => Reading.new(action: :buy,  move: :down, logic: :reversion),
        "bb_lower_breached"      => Reading.new(action: :buy,  move: :down, logic: :reversion),
        "ma200_crossed_above"    => Reading.new(action: :buy,  move: :up,   logic: :trend),
        "ma50_crossed_above"     => Reading.new(action: :buy,  move: :up,   logic: :trend),
        "rsi_overbought_entered" => Reading.new(action: :sell, move: :up,   logic: :reversion),
        "bb_upper_breached"      => Reading.new(action: :sell, move: :up,   logic: :reversion),
        "ma200_crossed_below"    => Reading.new(action: :sell, move: :down, logic: :trend),
        "ma50_crossed_below"     => Reading.new(action: :sell, move: :down, logic: :trend)
      }.freeze

      ACTIONABLE_TYPES = READINGS.keys.freeze

      # @api public
      def self.for(observation_type)
        reading(observation_type)&.action
      end

      # @api public
      def self.reading(observation_type)
        READINGS[observation_type.to_s]
      end
    end
  end
end
