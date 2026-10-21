require "rails_helper"

RSpec.describe Trading::Contracts::SavePlanContract do
  def call(**overrides)
    described_class.new.call({ stocks_share: "50", crypto_share: "20", fixed_income_share: "30",
                               monthly_contribution: "5000" }.merge(overrides))
  end

  it "accepts form strings that sum to 100" do
    result = call

    expect(result).to be_success
    expect(result.to_h).to include(stocks_share: 50, monthly_contribution: BigDecimal("5000"))
  end

  it "says how far from 100 the shares are" do
    result = call(fixed_income_share: "25")

    expect(result.errors.to_h[:fixed_income_share].first).to eq("Suman 95%, y deben sumar 100%. Faltan 5 puntos.")
  end

  it "needs every field: nothing is filled in on the owner's behalf" do
    expect(call(stocks_share: "")).to be_failure
    expect(call(monthly_contribution: "")).to be_failure
  end

  it "rejects a share above 100 and a negative contribution" do
    expect(call(stocks_share: "101")).to be_failure
    expect(call(monthly_contribution: "-5")).to be_failure
  end
end
