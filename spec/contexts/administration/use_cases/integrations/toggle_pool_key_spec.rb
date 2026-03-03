require "rails_helper"

RSpec.describe Administration::UseCases::Integrations::TogglePoolKey do
  let(:admin) { create(:user, :admin) }
  let!(:pool_key) { create(:api_key_pool, name: "Production", enabled: true) }

  describe ".call" do
    it "toggles enabled to false" do
      result = described_class.call(admin: admin, params: { id: pool_key.id })
      expect(result).to be_success
      expect(pool_key.reload.enabled).to be false
    end

    it "toggles enabled back to true" do
      pool_key.update!(enabled: false)
      result = described_class.call(admin: admin, params: { id: pool_key.id })
      expect(result).to be_success
      expect(pool_key.reload.enabled).to be true
    end

    it "publishes PoolKeyToggled event" do
      expect(EventBus).to receive(:publish).with(instance_of(Administration::Events::PoolKeyToggled))
      described_class.call(admin: admin, params: { id: pool_key.id })
    end

    context "when pool key not found" do
      it "returns not_found failure" do
        result = described_class.call(admin: admin, params: { id: 999_999 })
        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end
  end
end
