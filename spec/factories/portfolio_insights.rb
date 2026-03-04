FactoryBot.define do
  factory :portfolio_insight do
    user
    summary { "Portfolio shows moderate diversification with tech-heavy allocation." }
    observations { [ "Technology sector represents 60% of holdings", "Energy provides counterbalance" ] }
    risk_factors { [ "Sector concentration risk" ] }
    provider { "anthropic" }
    generated_at { Time.current }
  end
end
