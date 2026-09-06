module MarketData
  module Domain
    # ADR-014: the closed catalogue for the asset detail's Señales block. A row
    # is a pure function of one persisted `TechnicalReading`, and each state maps
    # to a phrase key — never to composed prose. The es-MX text lives in the
    # locale file (ADR-011).
    #
    # Every row states a fact the reading contains. RSI is the one that names a
    # condition, because 70/30 is the canonical threshold this codebase already
    # writes down in MarketHelper::OBSERVATION_PHRASES (D36: a chip is allowed
    # only where the threshold can be written down and defended).
    module IndicatorSignals
      OVERBOUGHT = 70
      OVERSOLD = 30

      # @api public
      def self.for(reading)
        return [] if reading.nil?

        [ rsi_row(reading), moving_average_row(reading),
          bollinger_row(reading), atr_row(reading) ].compact
      end

      def self.rsi_row(reading)
        rsi = reading[:rsi]
        return nil if rsi.nil?

        state = if rsi >= OVERBOUGHT then :overbought
        elsif rsi <= OVERSOLD then :oversold
        else :neutral
        end

        { indicator: :rsi, state: state, value: rsi }
      end
      private_class_method :rsi_row

      # Absent rather than partial when the close is missing: a band comparison
      # without the price it is compared against is not a reading.
      def self.moving_average_row(reading)
        close = reading[:close]
        ma50 = reading[:sma_50]
        return nil if close.nil? || ma50.nil?

        ma200 = reading[:sma_200]
        over_50 = close >= ma50
        return { indicator: :moving_average, state: over_50 ? :above_50 : :below_50, value: nil, ma50: ma50 } if ma200.nil?

        over_200 = close >= ma200
        state = if over_50 && over_200 then :above_both
        elsif !over_50 && !over_200 then :below_both
        elsif over_50 then :above_50_below_200
        else :below_50_above_200
        end

        { indicator: :moving_average, state: state, value: nil, ma50: ma50, ma200: ma200 }
      end
      private_class_method :moving_average_row

      # How far this asset travels in a normal day, as a share of its own price.
      # It carries no state, and deliberately: measured across the assets on
      # file the figure spans 0.27% to 7.2%, so any threshold for "volatile"
      # would be invented and D36 forbids that. The magnitude reads on its own
      # and is the one number here that compares across assets.
      def self.atr_row(reading)
        atr = reading[:atr]
        close = reading[:close]
        return nil if atr.nil? || close.nil? || !close.positive?

        { indicator: :atr, state: :rango_diario, value: (atr.to_d / close.to_d * 100) }
      end
      private_class_method :atr_row

      def self.bollinger_row(reading)
        close = reading[:close]
        upper = reading[:bb_upper]
        lower = reading[:bb_lower]
        return nil if close.nil? || upper.nil? || lower.nil?

        state = if close > upper then :above_upper
        elsif close < lower then :below_lower
        else :inside
        end

        { indicator: :bollinger, state: state, value: nil, upper: upper, lower: lower }
      end
      private_class_method :bollinger_row
    end
  end
end
