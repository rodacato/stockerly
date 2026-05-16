FactoryBot.define do
  factory :trend_score do
    asset
    score { 75 }
    label { :high_score }
    direction { :upward }
    calculated_at { Time.current }
  end
end
