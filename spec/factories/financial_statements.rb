FactoryBot.define do
  factory :financial_statement do
    asset
    statement_type { "income_statement" }
    period_type { "annual" }
    fiscal_date_ending { Date.new(2024, 9, 30) }
    fiscal_year { 2024 }
    currency { "USD" }
    data { { "total_revenue" => "391035000000", "net_income" => "93736000000" } }
    source { "yfinance" }
    fetched_at { Time.current }

    trait :balance_sheet do
      statement_type { "balance_sheet" }
      data { { "total_assets" => "352583000000", "total_shareholder_equity" => "62146000000" } }
    end

    trait :cash_flow do
      statement_type { "cash_flow" }
      data { { "operating_cashflow" => "118254000000", "capital_expenditures" => "-10959000000" } }
    end

    trait :quarterly do
      period_type { "quarterly" }
      fiscal_quarter { 4 }
    end
  end
end
