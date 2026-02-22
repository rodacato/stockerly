require "rails_helper"

RSpec.describe Integration, type: :model do
  subject(:integration) { build(:integration) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires provider_name" do
      integration.provider_name = nil
      expect(integration).not_to be_valid
    end

    it "requires unique provider_name" do
      create(:integration, provider_name: "Polygon.io")
      integration.provider_name = "Polygon.io"
      expect(integration).not_to be_valid
    end

    it "requires provider_type" do
      integration.provider_type = nil
      expect(integration).not_to be_valid
    end
  end

  describe "enums" do
    it "defines connection_status enum" do
      expect(Integration.connection_statuses).to eq(
        "connected" => 0, "syncing" => 1, "disconnected" => 2
      )
    end
  end

  describe "#masked_api_key" do
    it "returns masked key when present" do
      integration.api_key_encrypted = "sk_test_abc123xyz789"
      result = integration.masked_api_key
      expect(result).to start_with("••••••••••••")
      expect(result).to end_with("z789")
    end

    it "returns nil when api_key is nil" do
      integration.api_key_encrypted = nil
      expect(integration.masked_api_key).to be_nil
    end
  end

  describe "encryption" do
    it "encrypts the api_key_encrypted field" do
      integration = create(:integration, api_key_encrypted: "secret_key_123")
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT api_key_encrypted FROM integrations WHERE id = #{integration.id}"
      ).first["api_key_encrypted"]
      expect(raw_value).not_to eq("secret_key_123")
    end
  end
end
