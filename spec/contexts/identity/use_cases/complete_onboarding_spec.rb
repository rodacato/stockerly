require "rails_helper"

RSpec.describe Identity::UseCases::CompleteOnboarding do
  describe ".call" do
    it "stamps onboarded_at on the user" do
      user = create(:user, onboarded_at: nil)

      result = described_class.call(user: user)

      expect(result).to eq(user)
      expect(user.reload).to be_onboarded
    end
  end
end
