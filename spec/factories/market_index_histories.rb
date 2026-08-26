FactoryBot.define do
  factory :market_index_history do
    source { "Yahoo Finance/yfinance" }
    interval { "1d" }
    status { "confirmed" }
    fetched_at { Time.current }
    market_index
    sequence(:date) { |n| n.days.ago.to_date }
    close_value { 5_000.0000 }
  end
end
