FactoryBot.define do
  factory :trend_score do
    asset
    score { 75 }
    label { :strong }
    direction { :upward }
    calculated_at { Time.current }
  end
end
