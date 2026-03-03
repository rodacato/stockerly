require "rails_helper"

RSpec.describe SyncFundamentalJob, type: :job do
  let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, current_price: 189.43) }

  before do
    stub_alpha_vantage_overview("AAPL")
  end

  describe "#perform" do
    it "fetches overview and stores AssetFundamental" do
      expect { described_class.perform_now(asset.id) }
        .to change(AssetFundamental, :count).by(1)

      fundamental = AssetFundamental.last
      expect(fundamental.asset).to eq(asset)
      expect(fundamental.period_label).to eq("OVERVIEW")
      expect(fundamental.metrics["eps"]).to be_present
    end

    it "stores data_source from the gateway that succeeded" do
      described_class.perform_now(asset.id)

      fundamental = AssetFundamental.last
      expect(fundamental.source).to include("AlphaVantageGateway")
    end

    it "updates asset fundamentals_synced_at" do
      described_class.perform_now(asset.id)
      asset.reload
      expect(asset.fundamentals_synced_at).to be_within(5.seconds).of(Time.current)
    end

    it "publishes AssetFundamentalsUpdated event" do
      handler = class_double(MarketData::Handlers::LogFundamentalsUpdate, call: nil)
      EventBus.subscribe(MarketData::Events::AssetFundamentalsUpdated, handler)

      described_class.perform_now(asset.id)

      expect(handler).to have_received(:call).with(an_instance_of(MarketData::Events::AssetFundamentalsUpdated))
    end

    it "creates a success SystemLog" do
      expect { described_class.perform_now(asset.id) }
        .to change { SystemLog.where(severity: :success).count }.by_at_least(1)
    end

    it "upserts on subsequent calls (no duplicates)" do
      described_class.perform_now(asset.id)
      described_class.perform_now(asset.id)

      expect(AssetFundamental.where(asset: asset, period_label: "OVERVIEW").count).to eq(1)
    end

    context "when asset is disabled" do
      let(:asset) { create(:asset, symbol: "AAPL", sync_status: :disabled) }

      it "skips without API call" do
        expect { described_class.perform_now(asset.id) }
          .not_to change(AssetFundamental, :count)
      end
    end

    context "when asset is crypto" do
      let(:asset) { create(:asset, :crypto, symbol: "BTC", sync_status: :active) }

      it "skips crypto assets" do
        expect { described_class.perform_now(asset.id) }
          .not_to change(AssetFundamental, :count)
      end
    end

    context "when Alpha Vantage is rate limited" do
      before do
        WebMock.reset!
        stub_alpha_vantage_rate_limited
      end

      it "falls back to FMP when available" do
        stub_request(:get, %r{financialmodelingprep\.com/api/v3/profile/AAPL})
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: [ {
              symbol: "AAPL", companyName: "Apple Inc.", sector: "Technology",
              industry: "Consumer Electronics", exchangeShortName: "NASDAQ",
              currency: "USD", country: "US", mktCap: 3_100_000_000_000,
              pe: 31.5, eps: 6.42, beta: 1.24, lastDiv: 1.0,
              range: "164.08-237.49", price: 202.25, dcf: 158.32
            } ].to_json
          )

        expect { described_class.perform_now(asset.id) }
          .to change(AssetFundamental, :count).by(1)

        fundamental = AssetFundamental.last
        expect(fundamental.source).to include("FmpGateway")
      end
    end

    context "when all gateways fail" do
      before do
        WebMock.reset!
        stub_alpha_vantage_rate_limited
        stub_request(:get, %r{financialmodelingprep\.com/api/v3/profile/})
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "logs failure without creating fundamental" do
        expect { described_class.perform_now(asset.id) }
          .not_to change(AssetFundamental, :count)
      end
    end

    context "when asset not found" do
      it "returns silently" do
        expect { described_class.perform_now(-1) }
          .not_to change(AssetFundamental, :count)
      end
    end
  end
end
