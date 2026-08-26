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

  describe "provenance" do
    let(:asset) { create(:asset, symbol: "AAPL") }

    def price_event(source: nil)
      MarketData::Events::AssetPriceUpdated.new(
        asset_id: asset.id, symbol: "AAPL", old_price: "185.0", new_price: "189.43", source: source
      )
    end

    it "records which provider produced the row" do
      described_class.call(price_event(source: "Finnhub"))

      row = AssetPriceHistory.find_by(asset_id: asset.id, date: Date.current)
      expect(row.source).to eq("Finnhub")
      expect(row.interval).to eq("1d")
      expect(row.status).to eq("confirmed")
    end

    # as_of is when the number was true; fetched_at is when we asked. ADR-016
    # keeps them apart because two sources disagreeing and one being stale are
    # otherwise indistinguishable.
    it "keeps as_of and fetched_at as separate stamps" do
      described_class.call(price_event(source: "Finnhub"))

      row = AssetPriceHistory.find_by(asset_id: asset.id, date: Date.current)
      expect(row.as_of).to be_present
      expect(row.fetched_at).to be_present
    end

    it "says unknown rather than inventing a source for a publisher that omitted one" do
      described_class.call(price_event)

      expect(AssetPriceHistory.find_by(asset_id: asset.id, date: Date.current).source).to eq("unknown")
    end

    context "when a different source overwrites the row" do
      before do
        create(:asset_price_history, asset: asset, date: Date.current, source: "Alpaca/sip",
                                     open: 180.0, high: 192.0, low: 178.0, close: 185.0)
      end

      # Storing only the winner is only acceptable while replacements are
      # visible -- that record is what would decide whether multi-source is
      # worth having at all.
      it "does not replace it silently" do
        expect { described_class.call(price_event(source: "Finnhub")) }
          .to change { SystemLog.where(severity: :warning).count }.by(1)

        log = SystemLog.where(severity: :warning).last
        expect(log.error_message).to eq("Alpaca/sip → Finnhub")
      end

      it "stays quiet when the same source updates its own row" do
        expect { described_class.call(price_event(source: "Alpaca/sip")) }
          .not_to change { SystemLog.where(severity: :warning).count }
      end

      it "still records the new source" do
        described_class.call(price_event(source: "Finnhub"))

        expect(AssetPriceHistory.find_by(asset_id: asset.id, date: Date.current).source).to eq("Finnhub")
      end
    end
  end
end
