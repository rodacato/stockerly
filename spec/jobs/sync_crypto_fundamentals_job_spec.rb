require "rails_helper"

RSpec.describe SyncCryptoFundamentalsJob, type: :job do
  before { create(:integration, provider_name: "CoinGecko", api_key_encrypted: "test_key") }

  let!(:btc) { create(:asset, :crypto, symbol: "BTC") }

  describe "#perform" do
    context "when CoinGecko answers" do
      before { stub_coingecko_markets }

      it "writes the row LoadAssetDetail reads for a coin, not the equity one" do
        described_class.perform_now

        expect(btc.asset_fundamentals.pluck(:period_label)).to eq([ "CRYPTO_MARKET" ])
      end

      it "stores the metrics the crypto extract asks for, in its own vocabulary" do
        described_class.perform_now

        metrics = AssetFundamental.find_by(asset: btc, period_label: "CRYPTO_MARKET").metrics

        expect(metrics["circulating_supply"].to_d).to eq(19_600_000)
        expect(metrics["fully_diluted_valuation"].to_d).to eq(1_080_000_000_000)
        expect(metrics["ath_price"].to_d).to eq(73_750)
        expect(metrics["total_volume_24h"].to_d).to eq(28_400_000_000)
        expect(metrics["market_cap"].to_d).to eq(1_310_000_000_000)
      end

      it "records who the figures came from" do
        described_class.perform_now

        expect(AssetFundamental.last.source).to eq("MarketData::Gateways::CoingeckoGateway")
      end

      it "stamps the asset so the screen knows the data is fresh" do
        described_class.perform_now

        expect(btc.reload.fundamentals_synced_at).to be_within(5.seconds).of(Time.current)
      end

      it "announces the update like the equity sync does" do
        expect(EventBus).to receive(:publish)
          .with(an_instance_of(MarketData::Events::AssetFundamentalsUpdated))

        described_class.perform_now
      end

      it "spends one API call for the whole set" do
        create(:asset, :crypto, symbol: "ETH")

        described_class.perform_now

        expect(WebMock).to have_requested(:get, %r{coins/markets}).once
      end

      it "reads them back through the presenter the tab renders" do
        described_class.perform_now

        presenter = MarketData::Domain::FundamentalPresenter.new(
          asset: btc.reload, fundamental: AssetFundamental.last
        )

        expect(presenter.metric("ath_price").to_d).to eq(73_750)
        expect(presenter.volume_market_cap_ratio).to eq(0.0217)
      end
    end

    context "when a coin comes back missing" do
      before do
        create(:asset, :crypto, symbol: "ETH")
        stub_coingecko_markets
      end

      it "does not call a partial run a success" do
        described_class.perform_now

        log = SystemLog.last
        expect(log.severity).to eq("warning")
        expect(log.error_message).to include("ETH")
      end
    end

    context "when CoinGecko rate limits" do
      before { stub_coingecko_markets_rate_limited }

      it "writes a warning rather than an error, and stores nothing" do
        described_class.perform_now

        expect(SystemLog.last.severity).to eq("warning")
        expect(AssetFundamental.count).to be_zero
      end
    end

    context "when there is no crypto to sync" do
      before { btc.destroy }

      it "does not reach for the network" do
        described_class.perform_now

        expect(WebMock).not_to have_requested(:get, %r{coins/markets})
        expect(SystemLog.count).to be_zero
      end
    end
  end
end
