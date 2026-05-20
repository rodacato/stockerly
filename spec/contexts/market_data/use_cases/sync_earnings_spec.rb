require "rails_helper"

RSpec.describe MarketData::UseCases::SyncEarnings do
  before do
    create(:integration, provider_name: "Polygon.io", pool_key_value: "test_key")
  end

  describe ".call" do
    let!(:apple) { create(:asset, symbol: "AAPL", asset_type: :stock) }

    it "syncs earnings events from gateway" do
      stub_polygon_earnings("AAPL", count: 2)

      result = described_class.call
      expect(result).to be_success
      expect(result.value!).to eq(2)
      expect(EarningsEvent.where(asset: apple).count).to eq(2)
    end

    it "upserts without duplicating on same report_date" do
      stub_polygon_earnings("AAPL", count: 2)

      described_class.call
      described_class.call

      expect(EarningsEvent.where(asset: apple).count).to eq(2)
    end

    it "skips assets where gateway fails" do
      stub_polygon_earnings_rate_limited("AAPL")

      result = described_class.call
      expect(result).to be_success
      expect(result.value!).to eq(0)
    end

    it "publishes EarningsSynced event" do
      stub_polygon_earnings("AAPL", count: 1)
      allow(EventBus).to receive(:publish)

      described_class.call

      expect(EventBus).to have_received(:publish).with(an_instance_of(MarketData::Events::EarningsSynced))
    end

    it "syncs actual_eps when available from gateway" do
      stub_polygon_earnings_with_actuals("AAPL", count: 1)

      described_class.call

      event = EarningsEvent.find_by(asset: apple)
      expect(event.actual_eps).to be_present
      expect(event.actual_eps.to_f).to eq(1.7)
    end

    it "returns 0 when no stock assets exist" do
      apple.update!(asset_type: :crypto)

      result = described_class.call
      expect(result).to be_success
      expect(result.value!).to eq(0)
    end

    it "filters events beyond days_ahead window" do
      stub_polygon_earnings("AAPL", count: 2)

      result = described_class.call(days_ahead: 20)
      expect(result).to be_success
      # Only events within 20 days should be synced (none are within 20 days since stubs start at +1 month)
      expect(result.value!).to eq(0)
    end

    it "includes sync_issue assets in scope" do
      stuck = create(:asset, symbol: "STUCK", asset_type: :stock, sync_status: :sync_issue)
      stub_polygon_earnings("AAPL", count: 1)
      stub_polygon_earnings("STUCK", count: 1)

      result = described_class.call
      expect(result).to be_success
      expect(EarningsEvent.where(asset: stuck).count).to eq(1)
    end

    it "defaults to 90 days_ahead window" do
      expect(MarketData::UseCases::SyncEarnings::DEFAULT_DAYS_AHEAD).to eq(90)
    end

    it "is scheduled daily at 9am" do
      config = YAML.load_file(Rails.root.join("config/recurring.yml"))
      schedule = config.dig("production", "sync_earnings", "schedule")

      expect(schedule).to eq("at 9am every day")
    end

    describe "BMV path (Yahoo Finance)" do
      let!(:walmex) { create(:asset, :stock, symbol: "WALMEX.MX", exchange: "BMV", currency: "MXN") }

      it "routes .MX assets to Yahoo and bypasses the US chain" do
        stub_polygon_earnings_empty("AAPL")
        stub_yahoo_earnings("WALMEX.MX", dates: [ 3.days.from_now.to_date ], estimate: 1.24)

        result = described_class.call
        expect(result).to be_success
        expect(EarningsEvent.where(asset: walmex).count).to eq(1)

        event = EarningsEvent.find_by(asset: walmex)
        expect(event.estimated_eps.to_f).to eq(1.24)
        expect(event.confirmed).to be true
      end

      it "persists confirmed=false when Yahoo returns a date range" do
        stub_polygon_earnings_empty("AAPL")
        stub_yahoo_earnings("WALMEX.MX",
          dates: [ 3.days.from_now.to_date, 7.days.from_now.to_date ],
          estimate: 1.24
        )

        described_class.call
        event = EarningsEvent.find_by(asset: walmex)
        expect(event.confirmed).to be false
        expect(event.report_date).to eq(7.days.from_now.to_date)
      end

      it "skips BMV assets when Yahoo errors" do
        stub_polygon_earnings_empty("AAPL")
        stub_yahoo_earnings_error("WALMEX.MX", status: 500)

        result = described_class.call
        expect(result).to be_success
        expect(EarningsEvent.where(asset: walmex).count).to eq(0)
      end

      it "does NOT route BMV tickers through the Polygon/Finnhub chain" do
        stub_yahoo_earnings("WALMEX.MX", dates: [ 3.days.from_now.to_date ], estimate: 1.24)
        stub_polygon_earnings_empty("AAPL")
        # No Polygon stub for WALMEX.MX — if the use case mistakenly routed
        # BMV through the US chain, WebMock would raise on the unstubbed call.
        expect { described_class.call }.not_to raise_error
      end
    end
  end
end
