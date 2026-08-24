FactoryBot.define do
  factory :portfolio do
    user
    inception_date { Date.current }
  end
end
