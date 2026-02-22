FactoryBot.define do
  factory :alert_event do
    user
    alert_rule
    asset_symbol { "AAPL" }
    message { "AAPL crossed above $200.00" }
    event_status { :triggered }
    triggered_at { Time.current }

    trait :settled do
      event_status { :settled }
    end
  end
end
