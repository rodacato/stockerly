module Trading
  module Domain
    # What a screen does when a figure cannot be converted (ADR-0023): the
    # figure is absent, never zero, and the screen is told so it can say why.
    #
    # One instance per assembled screen. Callers that convert without one are
    # the defect this exists to prevent — three paths on the Consolidado had no
    # guard at all and answered a missing rate with a 500.
    class FxDegradation
      def initialize
        @degraded = false
      end

      def degraded?
        @degraded
      end

      def figure(fallback = nil)
        yield
      rescue MissingFxRate
        @degraded = true
        fallback
      end
    end
  end
end
