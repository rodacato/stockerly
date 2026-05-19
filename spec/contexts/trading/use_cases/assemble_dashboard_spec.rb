require "rails_helper"

RSpec.describe Trading::UseCases::AssembleDashboard do
  let(:user) { create(:user) }
  let!(:portfolio) { create(:portfolio, user: user, buying_power: 5000.0) }

  describe ".call" do
    it "returns Success with dashboard data" do
      result = described_class.call(user: user)

      expect(result).to be_success
      data = result.value!
      expect(data).to have_key(:summary)
      expect(data).to have_key(:watchlist_items)
      expect(data).to have_key(:news)
      expect(data).to have_key(:trending)
      expect(data).to have_key(:indices)
      expect(data).to have_key(:sentiment)
      expect(data).to have_key(:fear_greed)
      expect(data).to have_key(:weekly_insight)
      expect(data).to have_key(:upcoming_maturities)
      expect(data).to have_key(:cetes_summary)
    end

    it "includes PortfolioSummary when portfolio exists" do
      result = described_class.call(user: user)
      expect(result.value![:summary]).to be_a(Trading::Domain::PortfolioSummary)
    end

    it "returns nil summary when no portfolio" do
      portfolio.destroy
      result = described_class.call(user: user.reload)
      expect(result.value![:summary]).to be_nil
    end

    it "loads watchlist items with assets" do
      asset = create(:asset)
      create(:watchlist_item, user: user, asset: asset)

      result = described_class.call(user: user)
      expect(result.value![:watchlist_items].size).to eq(1)
    end

    it "limits watchlist items to 10" do
      12.times do |i|
        asset = create(:asset, symbol: "T#{i}", name: "Test #{i}")
        create(:watchlist_item, user: user, asset: asset)
      end

      result = described_class.call(user: user)
      expect(result.value![:watchlist_items].size).to eq(10)
    end

    it "loads recent news articles" do
      create(:news_article)
      result = described_class.call(user: user)
      expect(result.value![:news].size).to eq(1)
    end

    it "loads trending assets by absolute change" do
      create(:asset, symbol: "UP", asset_type: :stock, change_percent_24h: 5.0, current_price: 100.0)
      create(:asset, symbol: "DOWN", asset_type: :stock, change_percent_24h: -3.0, current_price: 50.0)

      result = described_class.call(user: user)
      expect(result.value![:trending].first.symbol).to eq("UP")
    end

    it "loads market indices" do
      create(:market_index, symbol: "SPX")
      result = described_class.call(user: user)
      expect(result.value![:indices]).to be_present
    end

    it "calculates market sentiment" do
      result = described_class.call(user: user)
      sentiment = result.value![:sentiment]
      expect(sentiment).to have_key(:value)
      expect(sentiment).to have_key(:label)
    end

    it "includes fear & greed readings" do
      create(:fear_greed_reading, :crypto, fetched_at: 1.hour.ago)
      create(:fear_greed_reading, :stocks, fetched_at: 2.hours.ago)

      result = described_class.call(user: user)
      fg = result.value![:fear_greed]
      expect(fg[:crypto]).to be_a(FearGreedReading)
      expect(fg[:stocks]).to be_a(FearGreedReading)
    end

    it "returns nil fear & greed when no readings exist" do
      result = described_class.call(user: user)
      fg = result.value![:fear_greed]
      expect(fg[:crypto]).to be_nil
      expect(fg[:stocks]).to be_nil
    end

    it "includes fear & greed history as [fetched_at, value] pairs" do
      create(:fear_greed_reading, :crypto, value: 30, fetched_at: 2.days.ago)
      create(:fear_greed_reading, :crypto, value: 45, fetched_at: 1.day.ago)

      result = described_class.call(user: user)
      fg = result.value![:fear_greed]
      expect(fg[:crypto_history].size).to eq(2)
      expect(fg[:crypto_history].first.last).to eq(30)
      expect(fg[:crypto_history].last.last).to eq(45)
    end

    it "returns empty history when no readings exist" do
      result = described_class.call(user: user)
      fg = result.value![:fear_greed]
      expect(fg[:stocks_history]).to be_empty
    end

    it "includes weekly_insight key in result" do
      result = described_class.call(user: user)
      expect(result.value!).to have_key(:weekly_insight)
    end

    it "returns weekly insight with data when snapshots exist" do
      asset = create(:asset, symbol: "AAPL", change_percent_24h: 3.5)
      create(:position, portfolio: portfolio, asset: asset, status: :open)
      create(:portfolio_snapshot, portfolio: portfolio, date: 5.days.ago.to_date, total_value: 10_000)
      create(:portfolio_snapshot, portfolio: portfolio, date: Date.current, total_value: 10_500)

      result = described_class.call(user: user)
      insight = result.value![:weekly_insight]
      expect(insight[:has_data]).to be true
      expect(insight[:weekly_change]).to eq(5.0)
      expect(insight[:top_performer][:symbol]).to eq("AAPL")
    end

    it "returns weekly insight without data when no snapshots" do
      result = described_class.call(user: user)
      insight = result.value![:weekly_insight]
      expect(insight[:has_data]).to be false
    end

    it "returns weekly insight without data when no portfolio" do
      portfolio.destroy
      result = described_class.call(user: user.reload)
      insight = result.value![:weekly_insight]
      expect(insight[:has_data]).to be false
    end

    describe "upcoming_maturities (#29 JTBD #3)" do
      let!(:cetes) { create(:asset, :fixed_income, symbol: "CETES_28D") }

      it "returns positions maturing within 30 days, sorted by soonest first" do
        create(:position, portfolio: portfolio, asset: cetes, maturity_date: 25.days.from_now.to_date)
        create(:position, portfolio: portfolio, asset: cetes, maturity_date: 5.days.from_now.to_date)
        create(:position, portfolio: portfolio, asset: cetes, maturity_date: 12.days.from_now.to_date)

        result = described_class.call(user: user)
        maturities = result.value![:upcoming_maturities]

        expect(maturities.map { |p| (p.maturity_date - Date.current).to_i }).to eq([ 5, 12, 25 ])
      end

      it "excludes positions maturing beyond the 30-day window" do
        create(:position, portfolio: portfolio, asset: cetes, maturity_date: 40.days.from_now.to_date)
        create(:position, portfolio: portfolio, asset: cetes, maturity_date: 25.days.from_now.to_date)

        result = described_class.call(user: user)
        expect(result.value![:upcoming_maturities].size).to eq(1)
      end

      it "excludes expired (past-maturity) positions" do
        create(:position, portfolio: portfolio, asset: cetes, maturity_date: 2.days.ago.to_date)

        result = described_class.call(user: user)
        expect(result.value![:upcoming_maturities]).to be_empty
      end

      it "excludes closed positions" do
        create(:position, portfolio: portfolio, asset: cetes, maturity_date: 5.days.from_now.to_date, status: :closed, closed_at: Time.current)

        result = described_class.call(user: user)
        expect(result.value![:upcoming_maturities]).to be_empty
      end

      it "is empty when the user has no portfolio" do
        portfolio.destroy
        result = described_class.call(user: user.reload)
        expect(result.value![:upcoming_maturities]).to eq([])
      end
    end

    describe "cetes_summary (S09 #90 KPI card)" do
      let(:user) { create(:user, preferred_currency: "MXN") }
      let!(:portfolio) { create(:portfolio, user: user, buying_power: 5000.0) }
      let!(:cetes) { create(:asset, :fixed_income, symbol: "CETES_28D", current_price: 10.0) }

      it "aggregates count, total value in preferred currency, and soonest_days" do
        create(:position, portfolio: portfolio, asset: cetes, shares: 100, avg_cost: 10, maturity_date: 5.days.from_now.to_date)
        create(:position, portfolio: portfolio, asset: cetes, shares: 50,  avg_cost: 10, maturity_date: 12.days.from_now.to_date)

        result = described_class.call(user: user)
        summary = result.value![:cetes_summary]

        expect(summary[:count]).to eq(2)
        expect(summary[:soonest_days]).to eq(5)
        # 100 × 10 + 50 × 10 = 1500 MXN (already in preferred currency)
        expect(summary[:total_value].to_f).to eq(1500.0)
      end

      it "returns zero summary when no fixed-income maturities upcoming" do
        # Only an equity position, no CETES
        equity = create(:asset, currency: "MXN", current_price: 100)
        create(:position, portfolio: portfolio, asset: equity, shares: 10)

        result = described_class.call(user: user)
        expect(result.value![:cetes_summary]).to eq(count: 0, total_value: 0, soonest_days: nil)
      end

      it "returns nil when the user has no portfolio" do
        portfolio.destroy
        result = described_class.call(user: user.reload)
        expect(result.value![:cetes_summary]).to be_nil
      end
    end

    it "preloads asset_price_histories on watchlist items" do
      asset = create(:asset, symbol: "PRE1")
      create(:watchlist_item, user: user, asset: asset)
      create(:asset_price_history, asset: asset, date: Date.current, close: 100)

      result = described_class.call(user: user)
      watchlist_asset = result.value![:watchlist_items].first.asset

      expect(watchlist_asset.association(:asset_price_histories)).to be_loaded
    end

    it "preloads trend_scores on trending assets" do
      asset = create(:asset, symbol: "TRN", asset_type: :stock, current_price: 50.0, change_percent_24h: 8.0)
      create(:trend_score, asset: asset)

      result = described_class.call(user: user)
      trending_asset = result.value![:trending].find { |a| a.symbol == "TRN" }

      expect(trending_asset.association(:trend_scores)).to be_loaded
    end
  end
end
