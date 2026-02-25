require "rails_helper"

RSpec.describe PriceChartHelper do
  include PriceChartHelper

  let(:asset) { create(:asset, symbol: "AAPL", current_price: 189.0) }

  describe "#price_chart_data" do
    it "returns nil with fewer than 2 data points" do
      histories = [ build(:asset_price_history, asset: asset, date: Date.current, close: 180.0) ]
      expect(price_chart_data(histories)).to be_nil
    end

    it "returns chart data with sufficient price history" do
      histories = (0..9).map do |i|
        build(:asset_price_history, asset: asset, date: i.days.ago.to_date, close: 180.0 + i)
      end.reverse

      result = price_chart_data(histories)

      expect(result).to be_a(Hash)
      expect(result[:points]).to be_present
      expect(result[:area]).to be_present
      expect(result[:color]).to be_present
      expect(result[:min_price]).to eq(180.0)
      expect(result[:max_price]).to eq(189.0)
      expect(result[:first_date]).to be_a(Date)
      expect(result[:last_date]).to be_a(Date)
    end

    it "returns green color when price trend is up" do
      histories = [
        build(:asset_price_history, asset: asset, date: 1.day.ago.to_date, close: 100.0),
        build(:asset_price_history, asset: asset, date: Date.current, close: 110.0)
      ]
      result = price_chart_data(histories)
      expect(result[:color]).to eq("#10b981")
    end

    it "returns red color when price trend is down" do
      histories = [
        build(:asset_price_history, asset: asset, date: 1.day.ago.to_date, close: 110.0),
        build(:asset_price_history, asset: asset, date: Date.current, close: 100.0)
      ]
      result = price_chart_data(histories)
      expect(result[:color]).to eq("#ef4444")
    end

    it "handles flat prices without division by zero" do
      histories = [
        build(:asset_price_history, asset: asset, date: 1.day.ago.to_date, close: 100.0),
        build(:asset_price_history, asset: asset, date: Date.current, close: 100.0)
      ]
      result = price_chart_data(histories)
      expect(result).to be_a(Hash)
      expect(result[:points]).to be_present
    end
  end
end
