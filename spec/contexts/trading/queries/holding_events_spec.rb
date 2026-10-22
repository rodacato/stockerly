require "rails_helper"

RSpec.describe Trading::Queries::HoldingEvents do
  let(:user) { create(:user, onboarded_at: Time.current) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  def hold(asset, maturity_date: nil)
    create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open, maturity_date: maturity_date)
  end

  it "lists the maturities and reports a month ahead for what is held, nearest first" do
    hold(create(:asset, :fixed_income, symbol: "CETES_28D"), maturity_date: 10.days.from_now.to_date)
    held = create(:asset, symbol: "NVDA")
    hold(held)
    create(:earnings_event, asset: held, report_date: 3.days.from_now.to_date)

    expect(described_class.call(user: user)).to eq([
      { kind: :earnings, symbol: "NVDA", date: 3.days.from_now.to_date, days: 3 },
      { kind: :maturity, symbol: "CETES_28D", date: 10.days.from_now.to_date, days: 10 }
    ])
  end

  it "leaves out what is further than a month off, and what is not held" do
    hold(create(:asset, :fixed_income, symbol: "CETES_91D"), maturity_date: 60.days.from_now.to_date)
    create(:earnings_event, asset: create(:asset, symbol: "AMZN"), report_date: 3.days.from_now.to_date)
    hold(create(:asset, symbol: "NVDA"))

    expect(described_class.call(user: user)).to eq([])
  end

  it "has no events without a portfolio" do
    expect(described_class.call(user: user)).to eq([])
  end
end
