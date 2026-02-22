FactoryBot.define do
  factory :position do
    portfolio
    asset
    shares { 10.0 }
    avg_cost { 100.0 }
    currency { "USD" }
    status { :open }
    opened_at { Time.current }

    trait :closed do
      status { :closed }
      closed_at { Time.current }
    end
  end
end
