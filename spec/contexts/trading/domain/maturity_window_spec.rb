require "rails_helper"

RSpec.describe Trading::Domain::MaturityWindow do
  let(:portfolio) { create(:portfolio) }
  let(:cetes) { create(:asset, :fixed_income, symbol: "CETES28", currency: "MXN") }

  def position(maturity_date)
    create(:position, portfolio: portfolio, asset: cetes, shares: 1, avg_cost: 10,
                      status: :open, maturity_date: maturity_date)
  end

  it "counts the days left when the lot is close enough for that to be the news" do
    expect(described_class.days_until(position(3.days.from_now.to_date))).to eq(3)
  end

  it "counts the day a lot maturing today has left" do
    expect(described_class.days_until(position(Date.current))).to eq(0)
  end

  it "says nothing about a maturity too far out to report" do
    expect(described_class.days_until(position((described_class::DAYS + 1).days.from_now.to_date))).to be_nil
  end

  it "says nothing about a lot whose maturity has passed" do
    expect(described_class.days_until(position(1.day.ago.to_date))).to be_nil
  end

  it "says nothing about a position that has no maturity at all" do
    expect(described_class.days_until(position(nil))).to be_nil
  end
end
