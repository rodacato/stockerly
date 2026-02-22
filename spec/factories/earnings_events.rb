FactoryBot.define do
  factory :earnings_event do
    asset
    report_date { 1.month.from_now }
    timing { :before_market_open }
    estimated_eps { 2.50 }
  end
end
