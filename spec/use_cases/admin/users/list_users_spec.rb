require "rails_helper"

RSpec.describe Admin::Users::ListUsers do
  describe ".call" do
    let!(:user1) { create(:user, full_name: "Alice Investor", email: "alice@example.com") }
    let!(:user2) { create(:user, full_name: "Bob Trader", email: "bob@example.com") }

    it "returns all users with pagination" do
      result = described_class.call(params: {})

      expect(result).to be_success
      data = result.value!
      expect(data[:users].count).to eq(2)
      expect(data[:pagy]).to be_a(Pagy)
    end

    it "searches by name" do
      result = described_class.call(params: { search: "alice" })
      expect(result.value![:users].count).to eq(1)
      expect(result.value![:users].first.full_name).to eq("Alice Investor")
    end

    it "searches by email" do
      result = described_class.call(params: { search: "bob@" })
      expect(result.value![:users].count).to eq(1)
    end
  end
end
