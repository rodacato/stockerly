FactoryBot.define do
  factory :financial_statement do
    asset
    statement_type { "income_statement" }
    period_type { "annual" }
    fiscal_date_ending { Date.new(2024, 9, 30) }
    fiscal_year { 2024 }
    currency { "USD" }
    data { { "totalRevenue" => "391035000000", "netIncome" => "93736000000" } }
    source { "alpha_vantage" }
    fetched_at { Time.current }

    trait :balance_sheet do
      statement_type { "balance_sheet" }
      data { { "totalAssets" => "352583000000", "totalShareholderEquity" => "62146000000" } }
    end

    trait :cash_flow do
      statement_type { "cash_flow" }
      data { { "operatingCashflow" => "118254000000", "capitalExpenditures" => "10959000000" } }
    end

    trait :quarterly do
      period_type { "quarterly" }
      fiscal_quarter { 4 }
    end
  end
end
