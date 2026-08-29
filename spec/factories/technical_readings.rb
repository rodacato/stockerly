FactoryBot.define do
  factory :technical_reading do
    association :asset
    calculated_at { Time.current }
    readings do
      { "close" => 150.0, "rsi" => 55.0, "sma_50" => 145.0, "sma_200" => 130.0,
        "bb_upper" => 160.0, "bb_middle" => 148.0, "bb_lower" => 136.0 }
    end
  end
end
