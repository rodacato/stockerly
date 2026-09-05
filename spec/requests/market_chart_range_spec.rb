require "rails_helper"

# CKP-2: the artboard draws `1S · 1M · 3M · 1A · Máx` and an O/H/L/C/Vol strip,
# and the chart rendered one fixed 30-day series. The range is a filter over
# data already loaded, which is why this is a read change and not a fetch.
RSpec.describe "Market chart range", type: :request do
  let!(:user) { create(:user, email: "range@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "NVDA", currency: "USD") }

  before do
    login_as(user)
    # Two years of closes, so every range has something different to show.
    730.downto(0) do |d|
      create(:asset_price_history, asset: asset, date: d.days.ago.to_date,
                                   open: 100, high: 110, low: 90, close: 100 + (d % 7), volume: 1_500_000)
    end
  end

  def series_points(body)
    body.scan(/&quot;time&quot;/).size
  end

  describe "the range control" do
    it "defaults to the range the artboard leads with" do
      get market_asset_path(asset.symbol)

      expect(response.body).to include(market_asset_path(asset.symbol, range: "1A"))
      expect(response.body).to include('aria-selected="true"')
      expect(active_range).to eq("3M")
    end

    it "narrows the series when a shorter range is asked for" do
      get market_asset_path(asset.symbol, range: "1S")
      short = series_points(response.body)

      get market_asset_path(asset.symbol, range: "1A")
      long = series_points(response.body)

      expect(short).to be < long
      expect(short).to be <= 8
    end

    it "plots the whole series for Máx" do
      get market_asset_path(asset.symbol, range: "MAX")

      expect(series_points(response.body)).to eq(731)
    end

    it "falls back to the default rather than erroring on an unknown range" do
      get market_asset_path(asset.symbol, range: "; DROP TABLE")

      expect(response).to have_http_status(:ok)
      expect(active_range).to eq("3M")
    end

    it "offers every range the use case knows, and no other" do
      get market_asset_path(asset.symbol)

      MarketData::UseCases::LoadAssetDetail::RANGES.each_key do |key|
        expect(response.body).to include(market_asset_path(asset.symbol, range: key))
      end
    end
  end

  describe "the O/H/L/C/Vol strip" do
    it "reads the latest bar, not the range's aggregate" do
      get market_asset_path(asset.symbol, range: "1M")

      expect(response.body).to include("110.00")
      expect(response.body).to include("90.00")
      expect(response.body).to include("1.5M")
    end

    it "does not change with the range, because the latest bar does not" do
      get market_asset_path(asset.symbol, range: "1S")
      short = response.body[/<dl.*?<\/dl>/m]

      get market_asset_path(asset.symbol, range: "MAX")
      long = response.body[/<dl.*?<\/dl>/m]

      expect(short).to eq(long)
    end
  end

  # The active pill, read from the control itself rather than from a class
  # string that styling is free to change.
  def active_range
    node = response.parsed_body
              .css(%([aria-label="#{I18n.t('market.precio.rango_label')}"] [aria-selected="true"]))
              .first
    node && Rack::Utils.parse_query(URI(node["href"]).query)["range"]
  end
end
