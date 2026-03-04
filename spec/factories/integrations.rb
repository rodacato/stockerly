FactoryBot.define do
  factory :integration do
    sequence(:provider_name) { |n| "Provider #{n}" }
    provider_type { "Stocks & Forex" }
    connection_status { :connected }
    last_sync_at { 1.hour.ago }

    transient do
      pool_key_value { "test_key_abc123xyz789" }
    end

    after(:create) do |integration, evaluator|
      if evaluator.pool_key_value.present? && integration.api_key_pools.default_key.empty?
        create(:api_key_pool, :default, integration: integration, api_key_encrypted: evaluator.pool_key_value)
      end
    end

    trait :disconnected do
      connection_status { :disconnected }
      requires_api_key { false }
      pool_key_value { nil }
    end

    trait :keyless do
      requires_api_key { false }
      pool_key_value { nil }
    end

    trait :syncing do
      connection_status { :syncing }
    end
  end
end
