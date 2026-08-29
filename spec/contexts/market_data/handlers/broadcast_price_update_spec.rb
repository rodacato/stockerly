require "rails_helper"

RSpec.describe MarketData::Handlers::BroadcastPriceUpdate do
  include ActionCable::TestHelper

  describe ".call" do
    let!(:owner) { create(:user, preferred_currency: "MXN") }
    let(:asset)  { with_day_change(create(:asset, symbol: "AAPL", currency: "USD", current_price: 150), 2.5) }

    it "broadcasts the rendered price block to the asset's stream" do
      described_class.call(asset_id: asset.id)

      payload = ActiveSupport::JSON.decode(broadcasts("asset_#{asset.id}").last)
      expect(payload).to include(%(target="asset_price_#{asset.id}"))
      expect(payload).to include("150")
      expect(payload).to include("+2.5")
    end

    it "does nothing when asset not found" do
      expect { described_class.call(asset_id: -1) }
        .not_to change { broadcasts("asset_#{asset.id}").size }
    end

    it "does nothing before setup has created the account" do
      owner.destroy

      expect { described_class.call(asset_id: asset.id) }
        .not_to change { broadcasts("asset_#{asset.id}").size }
    end
  end
end
