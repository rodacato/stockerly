FactoryBot.define do
  factory :plan do
    portfolio
    stocks_share { 50 }
    crypto_share { 20 }
    fixed_income_share { 30 }
    monthly_contribution { 5_000 }
  end
end
