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
        expect(user.is_verified).to be true
        expect(user.email_verified_at).to be_present
      end

      it "bootstraps integrations" do
        expect {
          described_class.call(params: valid_params)
        }.to change(Integration, :count).by(9)
      end

      it "bootstraps market indices" do
        expect {
          described_class.call(params: valid_params)
        }.to change(MarketIndex, :count).by(6)
      end

      it "bootstraps FX rates" do
        expect {
          described_class.call(params: valid_params)
        }.to change(FxRate, :count).by(3)
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
