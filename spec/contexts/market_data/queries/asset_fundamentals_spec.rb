require "rails_helper"

RSpec.describe MarketData::Queries::AssetFundamentals do
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", currency: "USD", current_price: 110) }

  def ar_records_in(value)
    case value
    when ActiveRecord::Base then [ value ]
    when Hash then value.flat_map { |key, nested| ar_records_in(key) + ar_records_in(nested) }
    when Array then value.flat_map { |nested| ar_records_in(nested) }
    else []
    end
  end

  context "with fundamentals on file" do
    let!(:overview) do
      create(:asset_fundamental, asset: asset, calculated_at: Time.zone.parse("2026-10-20 08:00"))
    end

    it "returns the metrics the page shows, with the values its presenter computes" do
      result = described_class.call(symbol: "aapl")

      expect(result).to include(symbol: "AAPL", name: "Apple Inc.", currency: "USD",
                                as_of: Time.zone.parse("2026-10-20 08:00"),
                                period_label: "OVERVIEW", source: "api_overview")
      expect(result[:metrics]).to include(
        { key: "pe_ratio", value: BigDecimal("18.12"), unit: :ratio },
        { key: "net_margin", value: BigDecimal("0.2461"), unit: :percentage },
        { key: "roe", value: BigDecimal("1.57"), unit: :percentage },
        { key: "eps", value: BigDecimal("6.07"), unit: :currency },
        { key: "beta", value: BigDecimal("1.24"), unit: :ratio }
      )
    end

    it "lists exactly what the presenter resolves to a value, and nothing the page drops" do
      presenter = MarketData::Domain::FundamentalPresenter.new(asset: asset, fundamental: overview)
      expected = MarketData::Domain::MetricDefinitions.shown_for(asset)
                   .select { |definition| presenter.value(definition.key).present? }.map { |d| d.key.to_s }

      keys = described_class.call(symbol: "AAPL")[:metrics].pluck(:key)

      expect(keys).to eq(expected)
      expect(keys).not_to include("dividend_yield", "sector")
    end

    it "uses keys the locale can label" do
      keys = described_class.call(symbol: "AAPL")[:metrics].pluck(:key)

      expect(keys).to all(satisfy { |key| I18n.exists?("market.metricas.#{key}.nombre", :"es-MX") })
    end

    it "dates the reading by the row the page reads first, with the overview filling its gaps" do
      create(:asset_fundamental, asset: asset, period_label: "CALCULATED", source: "calculated",
                                 calculated_at: Time.zone.parse("2026-10-21 09:00"),
                                 metrics: { "gross_margin" => "0.46" })

      result = described_class.call(symbol: "AAPL")

      expect(result).to include(period_label: "CALCULATED", source: "calculated",
                                as_of: Time.zone.parse("2026-10-21 09:00"))
      expect(result[:metrics].pluck(:key)).to include("gross_margin", "beta")
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

  it "has no metrics when no fundamentals were fetched" do
    expect(described_class.call(symbol: "AAPL")).to include(metrics: [], as_of: nil, period_label: nil, source: nil)
  end
end
