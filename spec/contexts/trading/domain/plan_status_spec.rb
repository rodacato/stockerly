require "rails_helper"

RSpec.describe Trading::Domain::PlanStatus do
  let(:plan) { build(:plan, stocks_share: 50, crypto_share: 20, fixed_income_share: 30, monthly_contribution: 5_000) }
  let(:allocation) { { "stock" => 400.0, "etf" => 100.0, "crypto" => 200.0, "fixed_income" => 300.0 } }

  def status(allocation: self.allocation, contributed: 5_000, today: Date.new(2026, 10, 20))
    described_class.call(plan: plan, allocation: allocation, contributed: contributed, today: today)
  end

  it "reads each share as a whole percent of what is held, stocks and ETFs together" do
    expect(status.shares.map { |s| [ s.key, s.actual, s.target ] })
      .to eq([ [ :stocks_share, 50, 50 ], [ :crypto_share, 20, 20 ], [ :fixed_income_share, 30, 30 ] ])
    expect(status.off_shares).to be_empty
  end

  it "ignores an index, which cannot be held" do
    expect(status(allocation: allocation.merge("index" => 9_999.0)).shares.first.actual).to eq(50)
  end

  it "calls a share off its plan from eight points away, not before" do
    near = status(allocation: { "stock" => 57.0, "crypto" => 20.0, "fixed_income" => 23.0 })
    far = status(allocation: { "stock" => 58.0, "crypto" => 20.0, "fixed_income" => 22.0 })

    expect(near.off_shares).to be_empty
    expect(far.off_shares.map(&:key)).to eq([ :stocks_share, :fixed_income_share ])
  end

  it "has no shares when nothing priced is held" do
    expect(status(allocation: {}).shares).to eq([])
  end

  describe "the contribution" do
    it "is missing only after the tenth of the month, and only when nothing was added" do
      expect(status(contributed: 0, today: Date.new(2026, 10, 9)).contribution_missing?).to be(false)
      expect(status(contributed: 0, today: Date.new(2026, 10, 10)).contribution_missing?).to be(true)
      expect(status(contributed: 1_000, today: Date.new(2026, 10, 20)).contribution_missing?).to be(false)
    end

    it "is not missing when it could not be valued: unknown is not zero" do
      expect(status(contributed: nil).contribution_missing?).to be(false)
    end

    it "is never missing for a plan that plans none" do
      plan.monthly_contribution = 0

      expect(status(contributed: 0).contribution_missing?).to be(false)
    end
  end
end
