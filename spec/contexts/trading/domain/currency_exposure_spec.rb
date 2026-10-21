require "rails_helper"

RSpec.describe Trading::Domain::CurrencyExposure do
  it "reads the dollar share of the patrimonio and what a 5% move does to it" do
    result = described_class.call(by_currency: { "MXN" => 600.to_d, "USD" => 400.to_d })

    expect(result.usd_share).to eq(40)
    expect(result.effect_of(5)).to eq(20)
  end

  it "reads zero when nothing is held in dollars" do
    result = described_class.call(by_currency: { "MXN" => 600.to_d })

    expect(result.usd_share).to eq(0)
    expect(result.effect_of(5)).to eq(0)
  end

  it "has nothing to say about an empty patrimonio" do
    expect(described_class.call(by_currency: {})).to be_nil
  end
end
