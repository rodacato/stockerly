require "rails_helper"

RSpec.describe SendSuspensionEmail do
  describe ".async?" do
    it { expect(described_class.async?).to be true }
  end

  describe ".call" do
    let(:user) { create(:user) }

    it "enqueues a suspension email" do
      mailer_double = double(deliver_later: true)
      allow(UserMailer).to receive(:account_suspended).and_return(mailer_double)

      described_class.call(user_id: user.id)

      expect(UserMailer).to have_received(:account_suspended).with(user)
    end

    it "does nothing when user not found" do
      expect { described_class.call(user_id: -1) }.not_to raise_error
    end
  end
end
