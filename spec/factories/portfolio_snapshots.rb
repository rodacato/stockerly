FactoryBot.define do
  factory :portfolio_snapshot do
    portfolio
    date { Date.current }
    total_value { 50_000.00 }
    cash_value { 10_000.00 }
    invested_value { 40_000.00 }
  end
end
