require "rails_helper"

RSpec.describe InstrumentLabel do
  it "names a CETE by its term, the way a person says it" do
    expect(described_class.short("CETES_28D")).to eq("CETES 28d")
    expect(described_class.short("CETES_364D")).to eq("CETES 364d")
    expect(described_class.name("CETES_91D", "CETES 91 Days")).to eq("CETES a 91 días")
  end

  it "leaves every other symbol and name as they are" do
    %w[NVDA BTC AMXL.MX CETES CETES_28 XCETES_28D].each do |symbol|
      expect(described_class.short(symbol)).to eq(symbol)
      expect(described_class.name(symbol, "Nombre")).to eq("Nombre")
    end
  end
end
