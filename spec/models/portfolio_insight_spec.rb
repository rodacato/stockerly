require "rails_helper"

RSpec.describe PortfolioInsight, type: :model do
  it "validates presence of summary" do
    insight = PortfolioInsight.new(user: create(:user), summary: nil, generated_at: Time.current)
    expect(insight).not_to be_valid
    expect(insight.errors[:summary]).to include("can't be blank")
  end

  it "latest scope orders by generated_at desc" do
    user = create(:user)
    old = create(:portfolio_insight, user: user, generated_at: 2.days.ago)
    recent = create(:portfolio_insight, user: user, generated_at: 1.hour.ago)

    expect(PortfolioInsight.latest.first).to eq(recent)
    expect(PortfolioInsight.latest.last).to eq(old)
  end
end
