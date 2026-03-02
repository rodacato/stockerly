require "rails_helper"

RSpec.describe Trading::PeriodReturnsCalculator do
  let(:user) { create(:user) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let(:calculator) { described_class.new(portfolio) }

  describe "#calculate" do
    context "with no snapshots" do
      it "returns zero returns for all periods" do
        results = calculator.calculate

        expect(results.keys).to include("1D", "1W", "1M", "3M", "6M", "1Y", "YTD", "ALL")
        results.each_value do |gain_loss|
          expect(gain_loss.absolute).to eq(0.0)
          expect(gain_loss.percent).to eq(0.0)
        end
      end
    end

    context "with snapshots" do
      let!(:portfolio) { create(:portfolio, user: user, buying_power: 0) }
      let!(:asset) { create(:asset, :stock, symbol: "AAPL", current_price: 200.0) }
      let!(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10.0, avg_cost: 150.0, status: :open) }

      before do
        create(:portfolio_snapshot, portfolio: portfolio, date: 2.months.ago.to_date, total_value: 1800.0, cash_value: 0, invested_value: 1800.0)
        create(:portfolio_snapshot, portfolio: portfolio, date: 2.weeks.ago.to_date, total_value: 1900.0, cash_value: 0, invested_value: 1900.0)
        create(:portfolio_snapshot, portfolio: portfolio, date: 2.days.ago.to_date, total_value: 1950.0, cash_value: 0, invested_value: 1950.0)
      end

      it "computes 1M return using the nearest snapshot" do
        results = calculator.calculate

        one_month = results["1M"]
        expect(one_month.absolute).to be > 0
        expect(one_month.percent).to be > 0
      end

      it "computes ALL return from the first snapshot" do
        results = calculator.calculate

        all_time = results["ALL"]
        # current value: 10 * 200 + 0 buying_power = 2000, first snapshot: 1800
        expect(all_time.absolute).to eq(200.0)
        expect(all_time.percent).to be_within(0.5).of(11.11)
      end

      it "returns GainLoss objects for each period" do
        results = calculator.calculate

        results.each_value do |gain_loss|
          expect(gain_loss).to be_a(GainLoss)
        end
      end
    end
  end

  describe "#chart_data" do
    before do
      create(:portfolio_snapshot, portfolio: portfolio, date: 3.weeks.ago.to_date, total_value: 1800.0, cash_value: 0, invested_value: 1800.0)
      create(:portfolio_snapshot, portfolio: portfolio, date: 2.weeks.ago.to_date, total_value: 1850.0, cash_value: 0, invested_value: 1850.0)
      create(:portfolio_snapshot, portfolio: portfolio, date: 1.week.ago.to_date, total_value: 1900.0, cash_value: 0, invested_value: 1900.0)
      create(:portfolio_snapshot, portfolio: portfolio, date: 2.months.ago.to_date, total_value: 1700.0, cash_value: 0, invested_value: 1700.0)
    end

    it "returns data points for the given period" do
      data = calculator.chart_data(period: "1M")

      expect(data).to be_an(Array)
      expect(data.length).to eq(3) # 3w, 2w, 1w ago (2m ago is outside 1M)
      expect(data.first).to have_key(:date)
      expect(data.first).to have_key(:value)
    end

    it "filters by period duration" do
      data = calculator.chart_data(period: "1W")

      expect(data.length).to eq(1) # only the 1-week-ago snapshot
    end

    it "orders by date ascending" do
      data = calculator.chart_data(period: "1M")

      dates = data.map { |d| d[:date] }
      expect(dates).to eq(dates.sort)
    end
  end
end
