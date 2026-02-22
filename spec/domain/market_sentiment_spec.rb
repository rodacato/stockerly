require "rails_helper"

RSpec.describe MarketSentiment do
  describe ".for_user" do
    let(:user) { create(:user) }

    it "returns Neutral when user has no watchlist items" do
      result = MarketSentiment.for_user(user)
      expect(result[:value]).to eq(50)
      expect(result[:label]).to eq("Neutral")
    end

    it "calculates sentiment from watchlist asset trend scores" do
      asset1 = create(:asset, symbol: "BULL1")
      asset2 = create(:asset, symbol: "BULL2")
      create(:watchlist_item, user: user, asset: asset1)
      create(:watchlist_item, user: user, asset: asset2)
      create(:trend_score, asset: asset1, score: 80, calculated_at: Time.current)
      create(:trend_score, asset: asset2, score: 90, calculated_at: Time.current)

      result = MarketSentiment.for_user(user)
      expect(result[:value]).to eq(85)
      expect(result[:label]).to eq("Very Bullish")
    end

    it "uses latest trend score per asset" do
      asset = create(:asset, symbol: "LATEST")
      create(:watchlist_item, user: user, asset: asset)
      create(:trend_score, asset: asset, score: 30, calculated_at: 1.day.ago)
      create(:trend_score, asset: asset, score: 75, calculated_at: Time.current)

      result = MarketSentiment.for_user(user)
      expect(result[:value]).to eq(75)
      expect(result[:label]).to eq("Bullish")
    end
  end

  describe ".global" do
    it "returns Neutral when no trend scores exist" do
      result = MarketSentiment.global
      expect(result[:value]).to eq(50)
      expect(result[:label]).to eq("Neutral")
    end

    it "calculates from latest 50 trend scores" do
      asset = create(:asset, symbol: "GLB")
      create(:trend_score, asset: asset, score: 15, calculated_at: Time.current)

      result = MarketSentiment.global
      expect(result[:value]).to eq(15)
      expect(result[:label]).to eq("Very Bearish")
    end
  end

  describe "label ranges" do
    {
      10 => "Very Bearish",
      30 => "Bearish",
      50 => "Neutral",
      70 => "Bullish",
      95 => "Very Bullish"
    }.each do |score, expected_label|
      it "returns '#{expected_label}' for score #{score}" do
        asset = create(:asset, symbol: "L#{score}")
        user = create(:user, email: "label#{score}@example.com")
        create(:watchlist_item, user: user, asset: asset)
        create(:trend_score, asset: asset, score: score, calculated_at: Time.current)

        result = MarketSentiment.for_user(user)
        expect(result[:label]).to eq(expected_label)
      end
    end
  end
end
