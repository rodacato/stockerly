FactoryBot.define do
  factory :integration do
    sequence(:provider_name) { |n| "Provider #{n}" }
    provider_type { "Stocks & Forex" }
    connection_status { :connected }
    api_key_encrypted { "sk_test_abc123xyz789" }
    last_sync_at { 1.hour.ago }

    trait :disconnected do
      connection_status { :disconnected }
      api_key_encrypted { nil }
    end

    trait :syncing do
      connection_status { :syncing }
    end
  end
end
