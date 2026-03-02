require "rails_helper"

RSpec.describe MarketData::PeHistoryCalculator do
  describe ".calculate" do
    let(:asset) { create(:asset, symbol: "AAPL", current_price: 200.0) }

    it "calculates P/E ratios from price histories and EPS" do
      histories = [
        create(:asset_price_history, asset: asset, date: 2.days.ago.to_date, close: 150.0),
        create(:asset_price_history, asset: asset, date: 1.day.ago.to_date, close: 200.0)
      ]

      result = described_class.calculate(price_histories: histories, eps: "6.07")

      expect(result.size).to eq(2)
      expect(result.first[:pe_ratio]).to eq((150.0 / 6.07).round(2))
      expect(result.last[:pe_ratio]).to eq((200.0 / 6.07).round(2))
      expect(result.first[:date]).to eq(2.days.ago.to_date)
    end

    it "returns empty array when EPS is nil or zero" do
      histories = [ create(:asset_price_history, asset: asset, date: Date.current, close: 150.0) ]

      expect(described_class.calculate(price_histories: histories, eps: nil)).to eq([])
      expect(described_class.calculate(price_histories: histories, eps: "0")).to eq([])
      expect(described_class.calculate(price_histories: [], eps: "6.07")).to eq([])
    end
  end
end
