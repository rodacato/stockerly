require "rails_helper"

RSpec.describe Plan, type: :model do
  it "is valid when the three shares sum to 100" do
    expect(build(:plan)).to be_valid
  end

  it "rejects shares that do not sum to 100" do
    plan = build(:plan, fixed_income_share: 25)

    expect(plan).not_to be_valid
    expect(plan.errors[:base]).to include("Los tres tipos deben sumar 100%")
  end

  it "rejects a share outside 0..100 and a negative contribution" do
    expect(build(:plan, stocks_share: 120, crypto_share: -10, fixed_income_share: -10)).not_to be_valid
    expect(build(:plan, monthly_contribution: -1)).not_to be_valid
  end

  it "allows only one plan per portfolio" do
    existing = create(:plan)

    expect { create(:plan, portfolio: existing.portfolio) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "reads its shares as a hash" do
    expect(build(:plan).shares).to eq(stocks_share: 50, crypto_share: 20, fixed_income_share: 30)
  end
end
