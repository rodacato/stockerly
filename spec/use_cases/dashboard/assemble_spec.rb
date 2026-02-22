require "rails_helper"

RSpec.describe Dashboard::Assemble do
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
    end

    it "includes PortfolioSummary when portfolio exists" do
      result = described_class.call(user: user)
      expect(result.value![:summary]).to be_a(PortfolioSummary)
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
  end
end
