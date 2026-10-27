require "rails_helper"

RSpec.describe Alerts::Handlers::EvaluateAlertsOnPriceUpdate do
  describe ".async?" do
    it { expect(described_class.async?).to be true }
  end

  describe ".call" do
    let(:asset) { create(:asset, symbol: "AAPL", current_price: 150) }

    it "invokes Alerts::UseCases::EvaluateRules" do
      use_case = instance_double(Alerts::UseCases::EvaluateRules)
      allow(Alerts::UseCases::EvaluateRules).to receive(:new).and_return(use_case)
      allow(use_case).to receive(:call).and_return([])

      described_class.call(asset_id: asset.id, new_price: "160.0", old_price: "150.0")

      expect(use_case).to have_received(:call).with(asset_id: asset.id, new_price: "160.0", old_price: "150.0")
    end

    # The sync jobs publish "0" for an asset that had no price before.
    it "does not treat an asset's first price as a crossing" do
      fresh = create(:asset, symbol: "NEW", current_price: nil)
      create(:alert_rule, asset_symbol: "NEW", condition: :price_crosses_above, threshold_value: 100)

      expect(described_class.call(asset_id: fresh.id, new_price: "150", old_price: "0")).to be_empty
    end
  end
end
