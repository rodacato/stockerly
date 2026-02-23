FactoryBot.define do
  factory :asset do
    sequence(:name) { |n| "Asset #{n}" }
    sequence(:symbol) { |n| "SYM#{n}" }
    asset_type { :stock }
    sync_status { :active }
    current_price { 150.0000 }
    change_percent_24h { 1.25 }
    sector { "Technology" }
    exchange { "NASDAQ" }
    price_updated_at { Time.current }

    trait :crypto do
      asset_type { :crypto }
      sector { nil }
      exchange { nil }
      data_source { "CoinGecko API" }
    end

    trait :index do
      asset_type { :index }
      sector { nil }
    end

    trait :etf do
      asset_type { :etf }
      sector { nil }
      exchange { "NASDAQ" }
      data_source { "Polygon.io" }
    end

    trait :fixed_income do
      asset_type { :fixed_income }
      sector { nil }
      exchange { "Banxico" }
      country { "MX" }
      yield_rate { 11.15 }
      maturity_date { 28.days.from_now.to_date }
      face_value { 10.0 }
      sync_status { :disabled }
    end

    trait :mexican do
      exchange { "BMV" }
      country { "MX" }
      data_source { "Yahoo Finance" }
    end

    trait :disabled do
      sync_status { :disabled }
    end

    trait :sync_issue do
      sync_status { :sync_issue }
    end

    trait :with_logo do
      logo_url { "https://logo.clearbit.com/example.com" }
    end

    trait :stale_price do
      price_updated_at { 1.hour.ago }
    end
  end
end
