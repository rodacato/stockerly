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
      allow(use_case).to receive(:call).and_return(Dry::Monads::Success([]))

      described_class.call(asset_id: asset.id, new_price: "160.0", old_price: "150.0")

      expect(use_case).to have_received(:call).with(asset_id: asset.id, new_price: "160.0", old_price: "150.0")
    end
  end
end
