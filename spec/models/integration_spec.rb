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
    it "returns masked key when pool key present" do
      integration = create(:integration, pool_key_value: "test_key_abc123xyz789")
      result = integration.masked_api_key
      expect(result).to start_with("••••••••••••")
      expect(result).to end_with("z789")
    end

    it "returns nil when no pool keys" do
      integration = create(:integration, pool_key_value: nil)
      expect(integration.masked_api_key).to be_nil
    end
  end

  describe "#increment_api_calls!" do
    let(:integration) { create(:integration, daily_api_calls: 0, daily_call_limit: 500, calls_reset_at: Time.current) }

    it "increments the daily_api_calls counter atomically" do
      expect { integration.increment_api_calls! }.to change { integration.reload.daily_api_calls }.from(0).to(1)
    end

    it "returns true when under budget" do
      expect(integration.increment_api_calls!).to be true
    end

    it "returns false when budget is exhausted" do
      integration.update!(daily_api_calls: 500)

      expect(integration.increment_api_calls!).to be false
      expect(integration.reload.daily_api_calls).to eq(500)
    end

    it "resets counter when calls_reset_at is from a previous day" do
      integration.update!(daily_api_calls: 450, calls_reset_at: 1.day.ago)

      expect(integration.increment_api_calls!).to be true
      expect(integration.reload.daily_api_calls).to eq(1)
    end
  end

  describe "#budget_exhausted?" do
    let(:integration) { create(:integration, daily_call_limit: 500, calls_reset_at: Time.current) }

    it "returns false when under limit" do
      integration.update!(daily_api_calls: 499)
      expect(integration.budget_exhausted?).to be false
    end

    it "returns true when at limit" do
      integration.update!(daily_api_calls: 500)
      expect(integration.budget_exhausted?).to be true
    end

    it "returns false when reset is stale (previous day)" do
      integration.update!(daily_api_calls: 500, calls_reset_at: 1.day.ago)
      expect(integration.budget_exhausted?).to be false
    end
  end

  describe "#minute_budget_exhausted?" do
    let(:integration) { create(:integration, max_requests_per_minute: 5, minute_reset_at: Time.current) }

    it "returns false when max_requests_per_minute is nil" do
      integration.update!(max_requests_per_minute: nil)
      expect(integration.minute_budget_exhausted?).to be false
    end

    it "returns false when under limit" do
      integration.update!(minute_calls: 4)
      expect(integration.minute_budget_exhausted?).to be false
    end

    it "returns true when at limit" do
      integration.update!(minute_calls: 5)
      expect(integration.minute_budget_exhausted?).to be true
    end

    it "returns false when minute window has expired" do
      integration.update!(minute_calls: 5, minute_reset_at: 2.minutes.ago)
      expect(integration.minute_budget_exhausted?).to be false
    end
  end

  describe "#increment_minute_calls!" do
    let(:integration) { create(:integration, max_requests_per_minute: 5, minute_calls: 0, minute_reset_at: Time.current) }

    it "increments the minute_calls counter" do
      expect { integration.increment_minute_calls! }.to change { integration.reload.minute_calls }.by(1)
    end

    it "resets counter when minute window has expired" do
      integration.update!(minute_calls: 4, minute_reset_at: 2.minutes.ago)
      integration.increment_minute_calls!
      expect(integration.reload.minute_calls).to eq(1)
    end
  end

  describe "#active_api_key" do
    it "returns default pool key when present" do
      integration = create(:integration, pool_key_value: "default_key_123")
      create(:api_key_pool, integration: integration, api_key_encrypted: "other_key_456")

      expect(integration.active_api_key).to eq("default_key_123")
    end

    it "returns least-used enabled pool key when no default" do
      integration = create(:integration, pool_key_value: nil)
      create(:api_key_pool, integration: integration, api_key_encrypted: "key_a", daily_calls: 10)
      create(:api_key_pool, integration: integration, api_key_encrypted: "key_b", daily_calls: 2)

      expect(integration.active_api_key).to eq("key_b")
    end

    it "returns nil when no pool keys" do
      integration = create(:integration, pool_key_value: nil)

      expect(integration.active_api_key).to be_nil
    end
  end

  describe "#api_key_configured?" do
    it "returns true with enabled pool keys" do
      integration = create(:integration)

      expect(integration.api_key_configured?).to be true
    end

    it "returns false when no pool keys" do
      integration = create(:integration, pool_key_value: nil)

      expect(integration.api_key_configured?).to be false
    end
  end
end
