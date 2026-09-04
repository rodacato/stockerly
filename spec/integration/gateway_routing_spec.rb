require "rails_helper"

# Characterization of which provider each sync path actually calls. Routing
# used to live in three disagreeing sites; it now resolves through
# DataSourceRegistry. These specs assert at the HTTP boundary so a re-route
# fails loudly instead of silently changing provider.
RSpec.describe "Gateway routing", type: :job do
  before do
    create(:integration, provider_name: "Finnhub", api_key_encrypted: "test_key")
    create(:integration, provider_name: "CoinGecko", api_key_encrypted: "test_key")
    create(:integration, provider_name: "Alpaca", api_key_encrypted: "PKID:secret")
    create(:integration, provider_name: "DataBursatil", api_key_encrypted: "test_token")
    GatewayChain.reset_breakers!
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

    # Yahoo is reachable only through the bridge now, and only ever as the last
    # link: it covers both markets, which no sanctioned provider does.
    it "falls back to Yahoo through the bridge when Finnhub fails" do
      asset = create(:asset, symbol: "AAPL", asset_type: :stock, price_updated_at: 10.minutes.ago)
      stub_finnhub_quote_not_found("AAPL")
      stub_yfinance_quote("AAPL", price: 190.00)

      SyncSingleAssetJob.perform_now(asset.id)

      expect(asset.reload.data_source).to eq("MarketData::Gateways::YfinanceGateway")
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
      it "sends BMV stocks to DataBursatil first" do
        asset = create(:asset, :mexican, symbol: "WALMEX.MX", price_updated_at: 10.minutes.ago)
        stub_databursatil("/v2/cotizaciones", { "WALMEX" => { "bmv" => databursatil_quote(last: 68.10) } })

        SyncSingleAssetJob.perform_now(asset.id)

        expect(a_request(:get, %r{api\.databursatil\.com/v2/cotizaciones})).to have_been_made
        expect(asset.reload.data_source).to eq("MarketData::Gateways::DataBursatilGateway")
      end

      # Asset type outranks market, which reverses what the country-first case
      # statement did: crypto is global, so a Mexican crypto goes to the
      # crypto source rather than to an exchange that cannot price it.
      it "sends Mexican crypto to CoinGecko, not down the BMV chain" do
        asset = create(:asset, :crypto, symbol: "BTC", country: "MX", price_updated_at: 10.minutes.ago)
        stub_coingecko_prices

        SyncSingleAssetJob.perform_now(asset.id)

        expect(a_request(:get, %r{api\.coingecko\.com})).to have_been_made
        expect(a_request(:get, %r{api\.databursatil\.com/v2/cotizaciones})).not_to have_been_made
      end

      it "sends Mexican fixed income down the BMV chain, which cannot price it" do
        asset = create(:asset, :fixed_income, symbol: "CETES28", sync_status: :active, price_updated_at: 10.minutes.ago)
        stub_databursatil("/v2/cotizaciones", {})

        SyncSingleAssetJob.perform_now(asset.id)

        expect(asset.reload.last_sync_error).to be_present
      end
    end

    # "Nobody serves this" is now data, not a programming error: the registry
    # answers with an empty chain and the job records the failure instead of
    # raising, which is what a source being dropped should look like.
    it "records a failure for an asset type no source claims" do
      asset = create(:asset, :fixed_income, symbol: "TBILL", country: "US", sync_status: :active, price_updated_at: 10.minutes.ago)

      expect { SyncSingleAssetJob.perform_now(asset.id) }.not_to raise_error

      expect(asset.reload.last_sync_error).to be_present
    end
  end

  # US stocks have no bulk path: SyncPriorityAssetsJob fans them out one by one
  # through SyncSingleAssetJob, covered above. The example that used to sit here
  # drove SyncBulkStocksJob, which nothing enqueued (#553).
  describe "bulk paths" do
    # Yahoo answers 429 to every request we can construct, from every network
    # tested, so the BMV bulk path no longer goes there.
    it "sends BMV assets to DataBursatil in bulk" do
      asset = create(:asset, :mexican, symbol: "WALMEX.MX")
      stub_databursatil("/v2/cotizaciones", { "WALMEX" => databursatil_quote(last: 68.10) && { "bmv" => databursatil_quote(last: 68.10) } })

      SyncBulkBmvJob.perform_now([ asset.id ])

      expect(a_request(:get, %r{api\.databursatil\.com/v2/cotizaciones})).to have_been_made
      expect(asset.reload.current_price.to_f).to eq(68.1)
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

    # The bug the consolidation fixed: this used to route by asset_type alone,
    # so a BMV asset asked Alpaca and then Yahoo and never DataBursatil.
    it "sends BMV history to DataBursatil, which the old route skipped" do
      asset = create(:asset, :mexican, symbol: "WALMEX.MX")
      stub_databursatil("/v2/historicos", { "WALMEX" => [] })
      stub_yfinance_not_found("WALMEX.MX")

      BackfillPriceHistoryJob.perform_now(asset.id)

      expect(a_request(:get, %r{api\.databursatil\.com/v2/historicos})).to have_been_made
      expect(a_request(:get, alpaca_bars)).not_to have_been_made
    end

    it "refuses fixed income outright" do
      asset = create(:asset, :fixed_income, symbol: "CETES28", sync_status: :active)

      BackfillPriceHistoryJob.perform_now(asset.id)

      expect(SystemLog.last.severity).to eq("error")
    end
  end
end
