module Admin
  module UsageHelper
    MIN_OFFERS = 5

    # Below a handful of offers a percentage is false precision, and an action
    # can land the week after its offer, so taken may exceed offered.
    def funnel_percent(taken, offered)
      return if offered < MIN_OFFERS || taken > offered

      "#{number_with_precision(taken * 100.0 / offered, precision: 0)}%"
    end
  end
end
