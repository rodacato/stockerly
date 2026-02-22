require "rails_helper"

RSpec.describe PortfolioSnapshot, type: :model do
  subject(:snapshot) { build(:portfolio_snapshot) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires date" do
      snapshot.date = nil
      expect(snapshot).not_to be_valid
    end

    it "requires total_value" do
      snapshot.total_value = nil
      expect(snapshot).not_to be_valid
    end

    it "requires cash_value" do
      snapshot.cash_value = nil
      expect(snapshot).not_to be_valid
    end

    it "requires invested_value" do
      snapshot.invested_value = nil
      expect(snapshot).not_to be_valid
    end

    it "requires unique date per portfolio" do
      portfolio = create(:portfolio)
      create(:portfolio_snapshot, portfolio: portfolio, date: "2026-02-20")
      dup = build(:portfolio_snapshot, portfolio: portfolio, date: "2026-02-20")
      expect(dup).not_to be_valid
    end
  end

  describe "scopes" do
    it ".recent orders by date desc" do
      portfolio = create(:portfolio)
      old = create(:portfolio_snapshot, portfolio: portfolio, date: 5.days.ago)
      recent = create(:portfolio_snapshot, portfolio: portfolio, date: Date.current)
      expect(PortfolioSnapshot.recent.first).to eq(recent)
    end
  end
end
