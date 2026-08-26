require "rails_helper"

RSpec.describe MarketHelper, type: :helper do
  describe "#asset_data_source_caption" do
    # It used to assert a source from the asset type, which is how it named
    # Yahoo for BMV prices that now arrive from DataBursatil.
    it "names the provider that actually produced the latest row, without repeating the venue" do
      asset = create(:asset, :mexican, symbol: "WALMEX.MX", currency: "MXN", exchange: "BMV")
      create(:asset_price_history, asset: asset, date: Date.current, source: "DataBursatil/bmv")

      expect(helper.asset_data_source_caption(asset)).to eq("Fuente: DataBursatil · BMV · MXN")
    end

    it "shows the venue when the sub-source names a real market" do
      asset = create(:asset, :mexican, symbol: "AMXB.MX", currency: "MXN", exchange: nil)
      create(:asset_price_history, asset: asset, date: Date.current, source: "DataBursatil/biva")

      expect(helper.asset_data_source_caption(asset)).to include("DataBursatil · BIVA")
    end

    # A feed is provenance, not something the reader can act on.
    it "hides a sub-source that is not a market" do
      asset = create(:asset, symbol: "AAPL", currency: "USD", exchange: "NASDAQ")
      create(:asset_price_history, asset: asset, date: Date.current, source: "Alpaca/sip")

      expect(helper.asset_data_source_caption(asset)).to eq("Fuente: Alpaca · NASDAQ · USD")
    end

    it "falls back when nothing has been recorded yet" do
      asset = create(:asset, symbol: "NEW", currency: "USD", exchange: "NASDAQ", data_source: nil)

      expect(helper.asset_data_source_caption(asset)).to include("sin registrar")
    end

    # Rows that predate provenance carry an explicit sentinel; showing it to a
    # reader would be worse than showing nothing.
    it "does not show the legacy sentinel" do
      asset = create(:asset, symbol: "OLD", currency: "USD", exchange: "NASDAQ", data_source: "Polygon.io")
      create(:asset_price_history, asset: asset, date: Date.current, source: "legacy:unknown")

      expect(helper.asset_data_source_caption(asset)).to eq("Fuente: Polygon.io · NASDAQ · USD")
    end
  end
end
