require "rails_helper"

RSpec.describe Administration::UseCases::Assets::UpdateAsset do
  describe ".call" do
    let(:admin) { create(:user, :admin) }
    let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", sector: "Technology", exchange: "NASDAQ", country: "US") }

    it "updates the asset name" do
      result = described_class.call(admin: admin, params: { id: asset.id, name: "Apple Corporation" })

      expect(result).to be_success
      expect(asset.reload.name).to eq("Apple Corporation")
    end

    it "updates multiple fields" do
      result = described_class.call(admin: admin, params: {
        id: asset.id, sector: "Tech", exchange: "NYSE", country: "MX"
      })

      expect(result).to be_success
      asset.reload
      expect(asset.sector).to eq("Tech")
      expect(asset.exchange).to eq("NYSE")
      expect(asset.country).to eq("MX")
    end

    it "updates logo_url" do
      result = described_class.call(admin: admin, params: {
        id: asset.id, logo_url: "https://new-logo.com/img.png"
      })

      expect(result).to be_success
      expect(asset.reload.logo_url).to eq("https://new-logo.com/img.png")
    end

    it "publishes AssetUpdated event" do
      expect(EventBus).to receive(:publish).with(an_instance_of(Administration::Events::AssetUpdated))

      described_class.call(admin: admin, params: { id: asset.id, name: "New Name" })
    end

    it "tracks changes in the event" do
      published_event = nil
      allow(EventBus).to receive(:publish) { |event| published_event = event }

      described_class.call(admin: admin, params: { id: asset.id, name: "New Name" })

      expect(published_event.changes).to include("name" => { from: "Apple Inc.", to: "New Name" })
    end

    it "returns Success with the updated asset" do
      result = described_class.call(admin: admin, params: { id: asset.id, name: "New Name" })

      expect(result).to be_success
      expect(result.value!).to eq(asset)
    end

    it "succeeds with no changes" do
      result = described_class.call(admin: admin, params: { id: asset.id })

      expect(result).to be_success
    end

    it "returns Failure for validation errors" do
      result = described_class.call(admin: admin, params: { id: asset.id, country: "INVALID" })

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "returns Failure when asset not found" do
      result = described_class.call(admin: admin, params: { id: 999_999 })

      expect(result).to be_failure
      expect(result.failure).to eq([ :not_found, "Asset not found" ])
    end
  end
end
