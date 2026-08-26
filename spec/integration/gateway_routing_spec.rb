require "rails_helper"

# Characterization of which provider each sync path actually calls today.
# Routing lives in nine hardcoded sites, not one, and the Alpaca and
# DataBursatil migrations move four of them. These specs assert at the HTTP
# boundary so a re-route fails loudly instead of silently changing provider.
RSpec.describe "Gateway routing", type: :job do
  before do
    create(:integration, provider_name: "Finnhub", api_key_encrypted: "test_key")
    create(:integration, provider_name: "CoinGecko", api_key_encrypted: "test_key")
    create(:integration, provider_name: "Alpaca", api_key_encrypted: "PKID:secret")
    SyncSingleAssetJob::CIRCUIT_BREAKERS.each_value(&:reset!)
  end

  def finnhub_quote = %r{finnhub\.io/api/v1/quote}
  def alpaca_bars = %r{data\.alpaca\.markets/v2/stocks/bars}
  def yahoo_chart(symbol) = %r{query\d\.finance\.yahoo\.com/v8/finance/chart/#{symbol}}

  describe "SyncSingleAssetJob" do
    # Alpaca cannot serve a current price on a Basic key, so the live-quote
    # role went to Finnhub rather than following the history to Alpaca.
    it "sends US stock quotes to Finnhub first" do
      asset = create(:asset, symbol: "AAPL", asset_type: :stock, price_updated_at: 10.minutes.ago)
      stub_finnhub_quote("AAPL", current: 189.43)

      SyncSingleAssetJob.perform_now(asset.id)

      expect(a_request(:get, finnhub_quote)).to have_been_made
      expect(asset.reload.data_source).to eq("MarketData::Gateways::FinnhubGateway")
    end

    it "falls back to Yahoo when Finnhub fails" do
      asset = create(:asset, symbol: "AAPL", asset_type: :stock, price_updated_at: 10.minutes.ago)
      stub_finnhub_quote_not_found("AAPL")
      stub_yahoo_finance_price("AAPL", price: 190.00)

      SyncSingleAssetJob.perform_now(asset.id)

      expect(a_request(:get, yahoo_chart("AAPL"))).to have_been_made
      expect(asset.reload.data_source).to eq("MarketData::Gateways::YahooFinanceGateway")
    end

    it "sends crypto to CoinGecko and never to the stock chain" do
      asset = create(:asset, :crypto, symbol: "BTC", price_updated_at: 10.minutes.ago)
      stub_coingecko_prices

      SyncSingleAssetJob.perform_now(asset.id)

      expect(a_request(:get, finnhub_quote)).not_to have_been_made
    end

    it "sends US ETFs and indices through the same chain as stocks" do
      %i[etf index].each do |type|
        asset = create(:asset, type, symbol: "SPY#{type}", price_updated_at: 10.minutes.ago)
        stub_finnhub_quote("SPY#{type}", current: 500.00)

        SyncSingleAssetJob.perform_now(asset.id)

        expect(
          a_request(:get, finnhub_quote).with(query: hash_including("symbol" => "SPY#{type}"))
        ).to have_been_made
      end
    end

    context "when the asset is Mexican" do
      it "sends BMV stocks to Yahoo" do
        asset = create(:asset, :mexican, symbol: "WALMEX.MX", price_updated_at: 10.minutes.ago)
        stub_yahoo_finance_price("WALMEX.MX", price: 68.10)

        SyncSingleAssetJob.perform_now(asset.id)

        expect(a_request(:get, yahoo_chart("WALMEX\\.MX"))).to have_been_made
      end

      # The country check precedes the asset_type case, so country wins over
      # type for every Mexican asset. Pinned as-is: this is the current
      # behaviour, not an endorsement of it.
      it "sends Mexican crypto to Yahoo rather than CoinGecko" do
        asset = create(:asset, :crypto, :mexican, symbol: "BTCMX", price_updated_at: 10.minutes.ago)
        stub_yahoo_finance_price("BTCMX", price: 1_200_000.00)

        SyncSingleAssetJob.perform_now(asset.id)

        expect(a_request(:get, yahoo_chart("BTCMX"))).to have_been_made
      end

      it "sends Mexican fixed income to Yahoo, which cannot price it" do
        asset = create(:asset, :fixed_income, symbol: "CETES28", sync_status: :active, price_updated_at: 10.minutes.ago)
        stub_yahoo_finance_not_found("CETES28")

        SyncSingleAssetJob.perform_now(asset.id)

        expect(a_request(:get, yahoo_chart("CETES28"))).to have_been_made
        expect(asset.reload.last_sync_error).to be_present
      end
    end

    it "raises for a non-Mexican asset type it has no route for" do
      asset = create(:asset, :fixed_income, symbol: "TBILL", country: "US", sync_status: :active, price_updated_at: 10.minutes.ago)

      expect { SyncSingleAssetJob.perform_now(asset.id) }
        .to raise_error(ArgumentError, /Unknown asset type/)
    end
  end

  describe "bulk paths" do
    it "sends US stocks to Alpaca's daily bars in one call" do
      asset = create(:asset, symbol: "AAPL", asset_type: :stock)
      stub_alpaca_bars({ "AAPL" => [ alpaca_bar(date: Date.current.to_s, close: 200.0, open: 198.0) ] })

      SyncBulkStocksJob.perform_now([ asset.id ])

      expect(a_request(:get, alpaca_bars).with(query: hash_including("feed" => "sip"))).to have_been_made
      expect(asset.reload.current_price.to_f).to eq(200.0)
    end

    it "sends BMV assets to Yahoo in bulk" do
      asset = create(:asset, :mexican, symbol: "WALMEX.MX")
      stub_yahoo_finance_bulk("WALMEX.MX" => { price: 68.10, change_percent: 0.5 })

      SyncBulkBmvJob.perform_now([ asset.id ])

      expect(a_request(:get, %r{query\d\.finance\.yahoo\.com})).to have_been_made
    end
  end

  describe "BackfillPriceHistoryJob" do
    it "sends crypto to CoinGecko" do
      asset = create(:asset, :crypto, symbol: "BTC")
      stub_coingecko_historical(coin_id: "bitcoin", days: 30)

      BackfillPriceHistoryJob.perform_now(asset.id)

      expect(a_request(:get, %r{api\.coingecko\.com})).to have_been_made
    end

    it "sends US stocks to Alpaca" do
      asset = create(:asset, symbol: "AAPL", asset_type: :stock)
      stub_alpaca_bars({ "AAPL" => [ alpaca_bar(date: 3.days.ago.to_date.to_s) ] })

      BackfillPriceHistoryJob.perform_now(asset.id)

      expect(a_request(:get, alpaca_bars)).to have_been_made
    end

    it "refuses fixed income outright" do
      asset = create(:asset, :fixed_income, symbol: "CETES28", sync_status: :active)

      BackfillPriceHistoryJob.perform_now(asset.id)

      expect(SystemLog.last.severity).to eq("error")
    end
  end
end
