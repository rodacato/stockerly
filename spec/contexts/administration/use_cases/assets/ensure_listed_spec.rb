require "rails_helper"

RSpec.describe Administration::UseCases::Assets::EnsureListed do
  it "lists the symbol with the identity attributes it was given" do
    asset = described_class.call(
      symbol: "CETES_28D",
      attributes: { name: "CETES 28 Days", asset_type: :fixed_income, exchange: "Banxico", country: "MX", currency: "MXN" }
    )

    expect(asset).to be_persisted
    expect(asset.name).to eq("CETES 28 Days")
    expect(asset.currency).to eq("MXN")
    expect(asset).to be_asset_type_fixed_income
  end

  it "returns the existing row without rewriting its identity" do
    existing = create(:asset, symbol: "CETES_28D", name: "Renamed by hand", asset_type: :fixed_income)

    asset = described_class.call(symbol: "CETES_28D", attributes: { name: "CETES 28 Days" })

    expect(asset.id).to eq(existing.id)
    expect(asset.name).to eq("Renamed by hand")
    expect(Asset.where(symbol: "CETES_28D").count).to eq(1)
  end

  it "leaves a disabled listing disabled" do
    create(:asset, symbol: "CETES_28D", asset_type: :fixed_income, sync_status: :disabled)

    expect(described_class.call(symbol: "CETES_28D", attributes: { name: "CETES 28 Days" })).to be_disabled
  end
end
