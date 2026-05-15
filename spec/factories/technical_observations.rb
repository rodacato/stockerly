FactoryBot.define do
  factory :technical_observation do
    asset
    observation_type { "rsi_oversold_entered" }
    observed_at { Time.current }
    indicator_snapshot { { rsi: 28.0, prev_rsi: 32.0, close: 145.5 } }

    trait :ma200_crossed_below do
      observation_type { "ma200_crossed_below" }
      indicator_snapshot { { close: 145.5, prev_close: 152.0, ma200: 150.0, prev_ma200: 150.5 } }
    end

    trait :bb_upper_breached do
      observation_type { "bb_upper_breached" }
      indicator_snapshot { { close: 180.0, prev_close: 175.0, bb_upper: 178.5, bb_lower: 160.0 } }
    end
  end
end
