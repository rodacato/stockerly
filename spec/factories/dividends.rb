FactoryBot.define do
  factory :dividend do
    asset
    ex_date { 1.month.from_now }
    amount_per_share { 0.24 }
    currency { "USD" }
  end
end
