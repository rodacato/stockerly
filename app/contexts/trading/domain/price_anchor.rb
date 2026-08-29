module Trading
  module Domain
    # What the current price is read against: your average cost when you hold
    # the asset, the price threshold you set when you only watch it.
    #
    # Values only, never records — the caller resolves which reference applies,
    # so Trading never reaches into an Alerts model to find one.
    class PriceAnchor
      Reading = Data.define(:kind, :reference, :percent)

      class << self
        def against_cost(price:, cost:)
          return nil if price.blank? || cost.blank? || cost.to_d.zero?

          Reading.new(kind: :cost, reference: cost.to_d,
                      percent: percent_of(price.to_d - cost.to_d, cost.to_d))
        end

        # Signed from the price's point of view: how far it still has to move to
        # reach the threshold, so a buy-below target reads negative.
        def against_threshold(price:, threshold:)
          return nil if price.blank? || threshold.blank? || price.to_d.zero?

          Reading.new(kind: :threshold, reference: threshold.to_d,
                      percent: percent_of(threshold.to_d - price.to_d, price.to_d))
        end

        private

        def percent_of(delta, base) = (delta / base * 100).round(1)
      end
    end
  end
end
