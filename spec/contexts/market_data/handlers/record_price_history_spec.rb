require "rails_helper"

RSpec.describe MarketData::Handlers::RecordPriceHistory do
  let(:asset) { create(:asset, symbol: "AAPL") }

  describe ".call" do
    context "when no history exists for today" do
      it "creates a new AssetPriceHistory record" do
        event = MarketData::Events::AssetPriceUpdated.new(
          asset_id: asset.id, symbol: "AAPL", old_price: "180.0", new_price: "189.43"
        )

        expect {
          described_class.call(event)
        }.to change(AssetPriceHistory, :count).by(1)

        record = AssetPriceHistory.last
        expect(record.asset_id).to eq(asset.id)
        expect(record.date).to eq(Date.current)
        expect(record.open.to_f).to eq(189.43)
        expect(record.high.to_f).to eq(189.43)
        expect(record.low.to_f).to eq(189.43)
        expect(record.close.to_f).to eq(189.43)
      end
    end

    context "when history already exists for today" do
      let!(:existing) do
        create(:asset_price_history,
          asset: asset, date: Date.current,
          open: 180.0, high: 192.0, low: 178.0, close: 185.0)
      end

      it "updates close price" do
        event = MarketData::Events::AssetPriceUpdated.new(
          asset_id: asset.id, symbol: "AAPL", old_price: "185.0", new_price: "189.43"
        )

        described_class.call(event)

        existing.reload
        expect(existing.close.to_f).to eq(189.43)
      end

      it "updates high if new price is higher" do
        event = MarketData::Events::AssetPriceUpdated.new(
          asset_id: asset.id, symbol: "AAPL", old_price: "185.0", new_price: "195.0"
        )

        described_class.call(event)

        existing.reload
        expect(existing.high.to_f).to eq(195.0)
      end

      it "updates low if new price is lower" do
        event = MarketData::Events::AssetPriceUpdated.new(
          asset_id: asset.id, symbol: "AAPL", old_price: "185.0", new_price: "175.0"
        )

        described_class.call(event)

        existing.reload
        expect(existing.low.to_f).to eq(175.0)
      end

      it "preserves open price" do
        event = MarketData::Events::AssetPriceUpdated.new(
          asset_id: asset.id, symbol: "AAPL", old_price: "185.0", new_price: "189.43"
        )

        described_class.call(event)

        existing.reload
        expect(existing.open.to_f).to eq(180.0)
      end

      it "does not create a new record" do
        event = MarketData::Events::AssetPriceUpdated.new(
          asset_id: asset.id, symbol: "AAPL", old_price: "185.0", new_price: "189.43"
        )

        expect {
          described_class.call(event)
        }.not_to change(AssetPriceHistory, :count)
      end
    end

    context "with Hash event (from async dispatch)" do
      it "handles hash events correctly" do
        event = { asset_id: asset.id, symbol: "AAPL", old_price: "180.0", new_price: "189.43" }

        expect {
          described_class.call(event)
        }.to change(AssetPriceHistory, :count).by(1)
      end
    end
  end
end
