FactoryBot.define do
  factory :api_key_pool do
    integration
    sequence(:name) { |n| "Key #{n}" }
    sequence(:api_key_encrypted) { |n| "pool_key_#{n}_abc123" }
    daily_calls { 0 }
    enabled { true }
    is_default { false }

    trait :default do
      is_default { true }
    end
  end
end
