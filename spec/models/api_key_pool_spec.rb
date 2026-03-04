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

    describe ".default_key" do
      it "returns only default keys" do
        default = create(:api_key_pool, :default, integration: integration)
        create(:api_key_pool, integration: integration)

        expect(described_class.default_key).to eq([ default ])
      end
    end
  end

  describe "is_default validation" do
    it "allows one default per integration" do
      integration = create(:integration)
      create(:api_key_pool, :default, integration: integration)

      duplicate = build(:api_key_pool, :default, integration: integration)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:is_default]).to be_present
    end

    it "allows defaults on different integrations" do
      int_a = create(:integration, provider_name: "Provider A")
      int_b = create(:integration, provider_name: "Provider B")
      create(:api_key_pool, :default, integration: int_a)

      second_default = build(:api_key_pool, :default, integration: int_b)
      expect(second_default).to be_valid
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
