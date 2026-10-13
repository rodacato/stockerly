module Trading
  module Domain
    # Incomplete valuations are absent, with the missing input reported separately.
    class FxDegradation
      def initialize
        @degraded = false
        @prices_unavailable = false
      end

      def prices_unavailable? = @prices_unavailable

      def degraded?
        @degraded
      end

      def figure(fallback = nil)
        yield
      rescue MissingFxRate
        @degraded = true
        fallback
      rescue MissingPrice
        @prices_unavailable = true
        fallback
      end
    end
  end
end
