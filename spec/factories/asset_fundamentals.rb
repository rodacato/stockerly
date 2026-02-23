FactoryBot.define do
  factory :asset_fundamental do
    asset
    period_label { "OVERVIEW" }
    metrics do
      {
        "eps" => "6.07",
        "book_value" => "3.95",
        "profit_margin" => "0.2461",
        "return_on_equity" => "1.5700",
        "revenue_per_share" => "25.23",
        "pe_ratio" => "31.25",
        "beta" => "1.24"
      }
    end
    source { "api_overview" }
    calculated_at { Time.current }

    trait :ttm do
      period_label { "TTM" }
      source { "calculated" }
    end
  end
end
