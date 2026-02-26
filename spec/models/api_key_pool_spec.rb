require "rails_helper"

RSpec.describe ApiKeyPool, type: :model do
  subject(:pool_key) { build(:api_key_pool) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires api_key_encrypted" do
      pool_key.api_key_encrypted = nil
      expect(pool_key).not_to be_valid
    end

    it "requires name" do
      pool_key.name = nil
      expect(pool_key).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to integration" do
      expect(pool_key).to respond_to(:integration)
    end
  end

  describe "scopes" do
    let(:integration) { create(:integration) }

    describe ".enabled" do
      it "returns only enabled keys" do
        enabled_key = create(:api_key_pool, integration: integration, enabled: true)
        create(:api_key_pool, integration: integration, enabled: false)

        expect(described_class.enabled).to eq([ enabled_key ])
      end
    end

    describe ".least_used" do
      it "orders by daily_calls ascending" do
        high = create(:api_key_pool, integration: integration, daily_calls: 10)
        low = create(:api_key_pool, integration: integration, daily_calls: 2)

        expect(described_class.least_used).to eq([ low, high ])
      end
    end
  end

  describe "#masked_api_key" do
    it "returns masked key with last 4 characters" do
      pool_key.api_key_encrypted = "secret_pool_key_xyz9"
      expect(pool_key.masked_api_key).to eq("••••••••••••xyz9")
    end

    it "returns nil when api_key is blank" do
      pool_key = build(:api_key_pool, api_key_encrypted: nil)
      expect(pool_key.masked_api_key).to be_nil
    end
  end

  describe "encryption" do
    it "encrypts the api_key_encrypted field" do
      pool_key = create(:api_key_pool, api_key_encrypted: "my_secret_key_1234")
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT api_key_encrypted FROM api_key_pools WHERE id = #{pool_key.id}"
      ).first["api_key_encrypted"]
      expect(raw_value).not_to eq("my_secret_key_1234")
    end
  end
end
