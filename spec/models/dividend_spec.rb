require "rails_helper"

RSpec.describe Dividend, type: :model do
  subject(:dividend) { build(:dividend) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires ex_date" do
      dividend.ex_date = nil
      expect(dividend).not_to be_valid
    end

    it "requires amount_per_share" do
      dividend.amount_per_share = nil
      expect(dividend).not_to be_valid
    end

    it "requires amount_per_share greater than 0" do
      dividend.amount_per_share = 0
      expect(dividend).not_to be_valid
    end

    it "requires unique ex_date per asset" do
      asset = create(:asset)
      create(:dividend, asset: asset, ex_date: "2026-03-15")
      dup = build(:dividend, asset: asset, ex_date: "2026-03-15")
      expect(dup).not_to be_valid
    end
  end

  describe "scopes" do
    it ".upcoming returns future dividends ordered by date" do
      past = create(:dividend, ex_date: 1.month.ago)
      future = create(:dividend, ex_date: 1.month.from_now)
      expect(Dividend.upcoming).to contain_exactly(future)
    end
  end

  describe "associations" do
    it "destroys dividend_payments on destroy" do
      dividend = create(:dividend)
      create(:dividend_payment, dividend: dividend)
      expect { dividend.destroy }.to change(DividendPayment, :count).by(-1)
    end
  end
end
