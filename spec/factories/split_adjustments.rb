FactoryBot.define do
  factory :split_adjustment do
    asset
    ex_date { 1.week.ago.to_date }
    ratio_from { 1 }
    ratio_to { 4 }
  end
end
