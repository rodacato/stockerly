require "rails_helper"

RSpec.describe Search::GlobalSearch do
  let(:user) { create(:user) }
  let!(:apple) { create(:asset, name: "Apple Inc.", symbol: "AAPL") }
  let!(:tesla) { create(:asset, name: "Tesla Inc.", symbol: "TSLA") }
  let!(:news) { create(:news_article, title: "Apple earnings report", related_ticker: "AAPL", published_at: 1.hour.ago) }

  describe "#call" do
    it "returns empty results for blank query" do
      result = described_class.call(query: "", user: user)
      expect(result).to be_success
      data = result.value!
      expect(data[:assets]).to be_empty
      expect(data[:alerts]).to be_empty
      expect(data[:news]).to be_empty
    end

    it "finds assets by name" do
      result = described_class.call(query: "apple", user: user)
      data = result.value!
      expect(data[:assets]).to include(apple)
      expect(data[:assets]).not_to include(tesla)
    end

    it "finds assets by symbol" do
      result = described_class.call(query: "TSLA", user: user)
      data = result.value!
      expect(data[:assets]).to include(tesla)
    end

    it "finds news articles by title" do
      result = described_class.call(query: "earnings", user: user)
      data = result.value!
      expect(data[:news]).to include(news)
    end

    it "finds user alert rules by symbol" do
      rule = create(:alert_rule, user: user, asset_symbol: "AAPL")
      result = described_class.call(query: "AAPL", user: user)
      data = result.value!
      expect(data[:alerts]).to include(rule)
    end

    it "works without a user" do
      result = described_class.call(query: "apple")
      data = result.value!
      expect(data[:assets]).to include(apple)
      expect(data[:alerts]).to be_empty
    end
  end
end
