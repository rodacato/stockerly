module Admin
  module UsageHelper
    # Counts in the single digits: a decimal would be false precision.
    def whole_percent(part, whole) = "#{number_with_precision(part * 100.0 / whole, precision: 0)}%"
  end
end
