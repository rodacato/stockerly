require "rails_helper"

RSpec.describe Administration::UseCases::Integrations::RemovePoolKey do
  let(:admin) { create(:user, :admin) }
  let!(:pool_key) { create(:api_key_pool, name: "Retired Key") }

  describe ".call" do
    it "destroys the pool key" do
      expect {
        described_class.call(admin: admin, params: { id: pool_key.id })
      }.to change(ApiKeyPool, :count).by(-1)
    end

    it "returns Success(:removed)" do
      result = described_class.call(admin: admin, params: { id: pool_key.id })
      expect(result).to be_success
      expect(result.value!).to eq(:removed)
    end

    it "publishes PoolKeyRemoved event" do
      expect(EventBus).to receive(:publish).with(instance_of(Administration::Events::PoolKeyRemoved))
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
