# What the current price is read against: your average cost when you hold
# the asset, the price threshold you set when you only watch it.
#
# Values only, never records — the caller resolves which reference applies,
# so neither Trading nor Alerts reaches into the other's models to find one.
class PriceAnchor
  Reading = Data.define(:kind, :reference, :percent)

  class << self
    def against_cost(price:, cost:)
      return nil if price.blank? || cost.blank?

      cost = cost.to_d
      return nil if cost.zero?

      Reading.new(kind: :cost, reference: cost, percent: percent_of(price.to_d - cost, cost))
    end

    # Signed from the price's point of view: how far it still has to move to
    # reach the threshold, so a buy-below target reads negative.
    def against_threshold(price:, threshold:)
      return nil if price.blank? || threshold.blank?

      price = price.to_d
      threshold = threshold.to_d
      return nil if price.zero?

      Reading.new(kind: :threshold, reference: threshold, percent: percent_of(threshold - price, price))
    end

    private

    def percent_of(delta, base) = (delta / base * 100).round(1)
  end
end
