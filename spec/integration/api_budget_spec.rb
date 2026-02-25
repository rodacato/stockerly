require "rails_helper"

RSpec.describe "API Budget Enforcement (E2E)", type: :model do
  let!(:integration) do
    create(:integration,
      provider_name: "Polygon.io",
      daily_api_calls: 0,
      daily_call_limit: 5,
      calls_reset_at: Time.current)
  end

  describe "budget exhaustion" do
    it "tracks calls and blocks when budget is exhausted" do
      5.times { expect(integration.increment_api_calls!).to be true }
      expect(integration.increment_api_calls!).to be false
      expect(integration.budget_exhausted?).to be true
    end

    it "resets budget on new day" do
      integration.update!(daily_api_calls: 5, calls_reset_at: 1.day.ago)

      expect(integration.budget_exhausted?).to be false
      expect(integration.increment_api_calls!).to be true
      expect(integration.reload.daily_api_calls).to eq(1)
    end
  end
end
