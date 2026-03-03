module MarketData
  module Domain
    # Pure domain service for CETES yield calculations.
    # Uses Mexican convention: 360-day year for discount rate math.
    class YieldCalculator
    class << self
      # Discount price of a CETES bond given face value, annual yield, and days to maturity.
      # Formula: P = FV / (1 + r/100 * d/360)
      def discount_price(face_value:, annual_yield:, days:)
        return face_value.to_d if days.to_i <= 0

        (face_value.to_d / (1 + annual_yield.to_d / 100 * days.to_d / 360)).round(6)
      end

      # Yield to maturity from known purchase price, face value, and days.
      # Formula: YTM = ((FV - P) / P) * (360 / d) * 100
      def yield_to_maturity(purchase_price:, face_value:, days:)
        return BigDecimal("0") if purchase_price.to_d == face_value.to_d || days.to_i <= 0

        gain = face_value.to_d - purchase_price.to_d
        ((gain / purchase_price.to_d) * (360.to_d / days.to_d) * 100).round(4)
      end

      # Total return in currency for a given quantity of bonds.
      def total_return(face_value:, purchase_price:, quantity:)
        ((face_value.to_d - purchase_price.to_d) * quantity.to_d).round(4)
      end

      # Total investment value at face value.
      def investment_value(face_value:, quantity:)
        (face_value.to_d * quantity.to_d).round(2)
      end
    end
    end
  end
end
