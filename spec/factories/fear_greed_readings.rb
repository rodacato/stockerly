FactoryBot.define do
  factory :fear_greed_reading do
    index_type { "crypto" }
    value { 50 }
    classification { "Neutral" }
    source { "alternative.me" }
    fetched_at { 1.hour.ago }

    trait :crypto do
      index_type { "crypto" }
      source { "alternative.me" }
    end

    trait :stocks do
      index_type { "stocks" }
      source { "cnn" }
    end

    trait :extreme_fear do
      value { 15 }
      classification { "Extreme Fear" }
    end

    trait :extreme_greed do
      value { 85 }
      classification { "Extreme Greed" }
    end

    trait :stale do
      fetched_at { 2.days.ago }
    end
  end
end
