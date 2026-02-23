require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, email: "test@example.com", full_name: "Jane Doe") }

  describe "#welcome" do
    let(:mail) { described_class.welcome(user) }

    it "sends to the user's email" do
      expect(mail.to).to eq([ "test@example.com" ])
    end

    it "sets the correct subject" do
      expect(mail.subject).to eq("Welcome to Stockerly!")
    end
  end

  describe "#password_reset" do
    let(:reset_url) { "https://stockerly.com/reset-password/abc123" }
    let(:mail) { described_class.password_reset(user, reset_url) }

    it "sends to the user's email" do
      expect(mail.to).to eq([ "test@example.com" ])
    end

    it "sets the correct subject" do
      expect(mail.subject).to eq("Reset your Stockerly password")
    end
  end

  describe "#account_suspended" do
    let(:mail) { described_class.account_suspended(user) }

    it "sends to the user's email" do
      expect(mail.to).to eq([ "test@example.com" ])
    end

    it "sets the correct subject" do
      expect(mail.subject).to eq("Your Stockerly account has been suspended")
    end
  end
end
