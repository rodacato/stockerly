FactoryBot.define do
  factory :api_key_pool do
    integration
    sequence(:api_key_encrypted) { |n| "pool_key_#{n}_abc123" }
    daily_calls { 0 }
    enabled { true }
  end
end
