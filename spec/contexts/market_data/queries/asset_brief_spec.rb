require "rails_helper"

RSpec.describe MarketData::Queries::AssetBrief do
  let!(:asset) do
    create(:asset, symbol: "AAPL", name: "Apple Inc.", currency: "USD", current_price: 110,
                   price_updated_at: Time.zone.parse("2026-10-21 15:00"), data_source: "Alpaca")
  end

  def ar_records_in(value)
    case value
    when ActiveRecord::Base then [ value ]
    when Hash then value.flat_map { |key, nested| ar_records_in(key) + ar_records_in(nested) }
    when Array then value.flat_map { |nested| ar_records_in(nested) }
    else []
    end
  end

  context "with everything on file" do
    before do
      create(:asset_price_history, asset: asset, date: Date.yesterday, close: 100)
      create(:asset_price_history, asset: asset, date: Date.current, close: 110)
      create(:asset_fundamental, asset: asset,
                                 metrics: { "fifty_two_week_low" => "90.5", "fifty_two_week_high" => "130.25" })
      create(:technical_reading, asset: asset, readings: { "close" => 110.0, "rsi" => 72.4, "sma_50" => 105.0 })
      4.times { |n| create(:news_article, related_ticker: "AAPL", title: "Headline #{n}", published_at: (n + 1).hours.ago) }
    end

    it "returns the brief as plain data" do
      brief = described_class.call(symbol: "aapl")

      expect(brief).to include(symbol: "AAPL", name: "Apple Inc.", currency: "USD")
      expect(brief[:quote]).to eq(price: 110.to_d, day_change_percent: 10.to_d,
                                  quoted_at: Time.zone.parse("2026-10-21 15:00"), source: "Alpaca")
      expect(brief[:range_52w]).to eq(low: BigDecimal("90.5"), high: BigDecimal("130.25"))
      expect(brief[:reading][:rows]).to include({ indicator: :rsi, state: :overbought, value: 72.4 },
                                                { indicator: :moving_average, state: :above_50, value: nil, ma50: 105.0 })
      expect(brief[:headlines].pluck(:title)).to eq([ "Headline 0", "Headline 1", "Headline 2" ])
      expect(brief[:headlines].first.keys).to eq(%i[title source published_at url])
    end

    it "holds no ActiveRecord object anywhere in the structure" do
      expect(ar_records_in(described_class.call(symbol: "AAPL"))).to be_empty
    end
  end

  it "returns nil for a symbol the catalogue does not carry" do
    expect(described_class.call(symbol: "NOPE")).to be_nil
  end

  it "resolves a symbol the asset used to carry" do
    asset.update!(symbol: "META", former_symbols: [ "FB" ])

    expect(described_class.call(symbol: "fb")[:symbol]).to eq("META")
  end

  it "has no quote when the asset has no price" do
    asset.update!(current_price: nil)

    expect(described_class.call(symbol: "AAPL")[:quote]).to be_nil
  end

  it "has no reading when none was persisted" do
    expect(described_class.call(symbol: "AAPL")[:reading]).to be_nil
  end
end
