require "rails_helper"

RSpec.describe KeyRotation do
  let!(:integration) { create(:integration, provider_name: "Polygon.io", pool_key_value: nil) }

  describe ".next_key_for" do
    context "with pool keys" do
      let!(:key_a) { create(:api_key_pool, integration: integration, api_key_encrypted: "key_a", daily_calls: 10) }
      let!(:key_b) { create(:api_key_pool, integration: integration, api_key_encrypted: "key_b", daily_calls: 5) }

      it "returns the least-used pool key" do
        result = described_class.next_key_for("Polygon.io")
        expect(result).to eq("key_b")
      end

      it "increments daily_calls on the selected key" do
        expect { described_class.next_key_for("Polygon.io") }
          .to change { key_b.reload.daily_calls }.from(5).to(6)
      end

      it "skips disabled keys" do
        key_b.update!(enabled: false)

        result = described_class.next_key_for("Polygon.io")
        expect(result).to eq("key_a")
      end
    end

    context "without pool keys" do
      it "returns nil" do
        result = described_class.next_key_for("Polygon.io")
        expect(result).to be_nil
      end
    end

    context "with unknown provider" do
      it "returns nil" do
        result = described_class.next_key_for("Unknown Provider")
        expect(result).to be_nil
      end
    end
  end
end
