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
  end
end
