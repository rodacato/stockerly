require "rails_helper"

RSpec.describe DividendPayment, type: :model do
  subject(:payment) { build(:dividend_payment) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires shares_held" do
      payment.shares_held = nil
      expect(payment).not_to be_valid
    end

    it "requires shares_held greater than 0" do
      payment.shares_held = 0
      expect(payment).not_to be_valid
    end

    it "requires total_amount" do
      payment.total_amount = nil
      expect(payment).not_to be_valid
    end
  end

  describe "scopes" do
    it ".recent orders by created_at desc" do
      old = create(:dividend_payment, created_at: 2.days.ago)
      recent = create(:dividend_payment, created_at: 1.hour.ago)
      expect(DividendPayment.recent.first).to eq(recent)
    end
  end
end
