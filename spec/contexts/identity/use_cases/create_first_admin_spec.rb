require "rails_helper"

RSpec.describe Identity::UseCases::CreateFirstAdmin do
  let(:valid_params) do
    {
      full_name: "Admin User",
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
  end

  describe ".call" do
    context "when no users exist" do
      it "creates an admin user" do
        result = described_class.call(params: valid_params)

        expect(result).to be_success
        user = result.value!
        expect(user.admin?).to be true
      end

      it "bootstraps integrations" do
        expect {
          described_class.call(params: valid_params)
        }.to change(Integration, :count).by(MarketData::Domain::ProviderDefaults::ALL.size)
      end

      it "bootstraps market indices" do
        expect {
          described_class.call(params: valid_params)
        }.to change(MarketIndex, :count).by(6)
      end

      # Setup runs before any API key exists, so the only rate it could write is
      # an invented one — and a fabricated rate is worse than a visible gap.
      it "writes no FX rate at all" do
        expect {
          described_class.call(params: valid_params)
        }.not_to change(FxRate, :count)
      end

      it "publishes FirstAdminCreated event" do
        expect(EventBus).to receive(:publish).with(an_instance_of(Identity::Events::FirstAdminCreated))

        described_class.call(params: valid_params)
      end
    end

    context "when users already exist" do
      before { create(:user) }

      it "returns Failure with :setup_complete" do
        result = described_class.call(params: valid_params)

        expect(result).to be_failure
        expect(result.failure.first).to eq(:setup_complete)
      end
    end

    context "with invalid params" do
      it "returns Failure with :validation" do
        result = described_class.call(params: valid_params.merge(email: "bad"))

        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation)
      end
    end
  end
end
