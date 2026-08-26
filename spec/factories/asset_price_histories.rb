FactoryBot.define do
  factory :asset_price_history do
    asset
    date { Date.current }
    open { 148.0 }
    high { 152.0 }
    low { 147.0 }
    close { 150.0 }
    volume { 50_000_000 }
    source { "Alpaca/sip" }
    interval { "1d" }
    status { "confirmed" }
    as_of { Time.current }
    fetched_at { Time.current }
  end
end
