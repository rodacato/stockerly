require "rails_helper"

RSpec.describe Trading::Domain::UpcomingDividendsPresenter do
  let(:portfolio) { create(:portfolio) }
  let(:asset) { create(:asset, :stock) }
  let!(:position) { create(:position, portfolio: portfolio, asset: asset, status: :open, shares: 100) }

  describe "#upcoming" do
    it "returns upcoming dividends with expected payout" do
      create(:dividend, asset: asset, ex_date: 2.weeks.from_now.to_date, amount_per_share: 0.50)

      results = described_class.new(portfolio).upcoming

      expect(results.size).to eq(1)
      expect(results.first.asset).to eq(asset)
      expect(results.first.shares).to eq(100)
      expect(results.first.expected_total).to eq(50.0)
    end

    it "excludes past dividends" do
      create(:dividend, asset: asset, ex_date: 1.week.ago.to_date, amount_per_share: 0.25)

      results = described_class.new(portfolio).upcoming
      expect(results).to be_empty
    end

    it "excludes dividends for assets without open positions" do
      other_asset = create(:asset, :stock)
      create(:dividend, asset: other_asset, ex_date: 1.month.from_now.to_date, amount_per_share: 0.30)

      results = described_class.new(portfolio).upcoming
      expect(results).to be_empty
    end

    it "returns empty when portfolio has no open positions" do
      empty_portfolio = create(:portfolio)
      results = described_class.new(empty_portfolio).upcoming
      expect(results).to be_empty
    end
  end
end
