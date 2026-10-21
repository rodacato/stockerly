require "rails_helper"

RSpec.describe MarketData::Queries::CurrentVolatility do
  def vix(value: 18.4, updated_at: Time.current)
    create(:market_index, symbol: "VIX", name: "VIX", value: value).tap { |index| index.update_columns(updated_at: updated_at) }
  end

  it "reads the level of a fresh VIX" do
    vix(value: 27)

    reading = described_class.call

    expect(reading.value).to eq(27)
    expect(reading.level).to eq(:elevated)
    expect(reading.as_of).to eq(Date.current)
  end

  it "survives a weekend, when the index does not move" do
    vix(updated_at: 3.days.ago)

    expect(described_class.call).not_to be_nil
  end

  it "is absent rather than calm once the reading is older than the window" do
    vix(updated_at: 6.days.ago)

    expect(described_class.call).to be_nil
  end

  it "is absent with no VIX or no value" do
    expect(described_class.call).to be_nil

    vix(value: nil)
    expect(described_class.call).to be_nil
  end
end
