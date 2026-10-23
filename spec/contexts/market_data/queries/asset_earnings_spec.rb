require "rails_helper"

RSpec.describe MarketData::Queries::AssetEarnings do
  let(:asset) { create(:asset, :stock, symbol: "NVDA") }

  it "reads the next report and the last reported quarter as plain data" do
    create(:earnings_event, asset: asset, report_date: 30.days.from_now.to_date, timing: :after_market_close, estimated_eps: 0.75)
    create(:earnings_event, asset: asset, report_date: 60.days.ago.to_date, estimated_eps: 0.64, actual_eps: 0.68)
    create(:earnings_event, asset: asset, report_date: 150.days.ago.to_date, estimated_eps: 0.50, actual_eps: 0.60)

    data = described_class.call(symbol: "nvda")

    expect(data[:next]).to eq(report_date: 30.days.from_now.to_date, timing: "after_market_close", estimated_eps: BigDecimal("0.75"))
    expect(data[:last]).to eq(report_date: 60.days.ago.to_date, actual_eps: BigDecimal("0.68"), estimated_eps: BigDecimal("0.64"))
  end

  it "does not count a past date with no actual figure as reported" do
    create(:earnings_event, asset: asset, report_date: 3.days.ago.to_date, actual_eps: nil)

    expect(described_class.call(symbol: "NVDA")).to eq(symbol: "NVDA", next: nil, last: nil)
  end

  # F3.4: reported after today's close, it is the last quarter, not the next.
  it "reads a quarter reported today as the last one" do
    create(:earnings_event, asset: asset, report_date: Date.current, actual_eps: 1.2, estimated_eps: 1.0)

    result = described_class.call(symbol: "NVDA")

    expect(result[:next]).to be_nil
    expect(result[:last][:report_date]).to eq(Date.current)
  end

  it "knows nothing of an unknown symbol" do
    expect(described_class.call(symbol: "NOPE")).to be_nil
  end
end
