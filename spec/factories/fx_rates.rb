FactoryBot.define do
  factory :fx_rate do
    base_currency { "USD" }
    sequence(:quote_currency) { |n| "CUR#{n}" }
    rate { 1.2500 }
    fetched_at { Time.current }
  end
end
