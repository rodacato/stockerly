FactoryBot.define do
  factory :trade do
    portfolio
    asset
    side { :buy }
    shares { 10.0 }
    price_per_share { 150.0 }
    total_amount { 1_500.0 }
    currency { "USD" }
    executed_at { Time.current }
  end
end
