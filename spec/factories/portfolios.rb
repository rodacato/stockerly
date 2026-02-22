FactoryBot.define do
  factory :portfolio do
    user
    buying_power { 10_000.00 }
    inception_date { Date.current }
  end
end
