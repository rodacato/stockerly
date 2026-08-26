FactoryBot.define do
  factory :integration do
    sequence(:provider_name) { |n| "Provider #{n}" }
    provider_type { "Stocks & Forex" }
    connection_status { :connected }
    last_sync_at { 1.hour.ago }
    api_key_encrypted { "test_key_abc123xyz789" }

    trait :disconnected do
      connection_status { :disconnected }
      requires_api_key { false }
      api_key_encrypted { nil }
    end

    trait :keyless do
      requires_api_key { false }
      api_key_encrypted { nil }
    end

    trait :syncing do
      connection_status { :syncing }
    end
  end
end
