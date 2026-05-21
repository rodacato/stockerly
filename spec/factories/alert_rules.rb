FactoryBot.define do
  factory :alert_rule do
    user
    asset_symbol { "AAPL" }
    condition { :price_crosses_above }
    threshold_value { 200.0000 }
    status { :active }

    trait :paused do
      status { :paused }
    end

    trait :dividend do
      condition { :dividend_ex_date }
      threshold_value { 0 }
      window_days { 7 }
    end

    # Marketwide rules don't bind to an asset; the form leaves asset_symbol
    # empty and the persistence path stores nil.
    trait :marketwide do
      asset_symbol { nil }
      threshold_value { nil }
      window_days { 7 }
    end
  end
end
