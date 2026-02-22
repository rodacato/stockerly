FactoryBot.define do
  factory :dividend_payment do
    portfolio
    dividend
    shares_held { 50.0 }
    total_amount { 12.0 }
  end
end
