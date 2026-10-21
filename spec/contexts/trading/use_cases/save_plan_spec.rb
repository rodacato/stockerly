require "rails_helper"

RSpec.describe Trading::UseCases::SavePlan do
  let(:portfolio) { create(:portfolio) }
  let(:params) { { stocks_share: "40", crypto_share: "10", fixed_income_share: "50", monthly_contribution: "3000" } }

  it "creates the plan the first time" do
    result = described_class.call(portfolio: portfolio, params: params)

    expect(result).to be_success
    expect(portfolio.reload.plan).to have_attributes(stocks_share: 40, monthly_contribution: 3_000)
  end

  it "replaces it afterwards instead of adding another" do
    described_class.call(portfolio: portfolio, params: params)
    described_class.call(portfolio: portfolio, params: params.merge(stocks_share: "30", crypto_share: "20"))

    expect(Plan.where(portfolio: portfolio).count).to eq(1)
    expect(portfolio.reload.plan.crypto_share).to eq(20)
  end

  it "fails on a validation error and leaves the saved plan alone" do
    described_class.call(portfolio: portfolio, params: params)

    result = described_class.call(portfolio: portfolio, params: params.merge(stocks_share: "10"))

    expect(result).to be_failure
    expect(result.failure.first).to eq(:validation)
    expect(portfolio.reload.plan.stocks_share).to eq(40)
  end
end
