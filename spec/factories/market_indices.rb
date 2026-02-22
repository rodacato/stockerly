FactoryBot.define do
  factory :market_index do
    sequence(:name) { |n| "Index #{n}" }
    sequence(:symbol) { |n| "IDX#{n}" }
    value { 5_000.0000 }
    change_percent { 0.75 }
    exchange { "NYSE" }
    is_open { true }

    trait :closed do
      is_open { false }
    end
  end
end
