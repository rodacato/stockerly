require "rails_helper"

RSpec.describe MarketData::UseCases::SyncPriceHistory do
  before { create(:integration, provider_name: "DataBursatil", api_key_encrypted: "token") }

  let(:asset) { create(:asset, :mexican, symbol: "WALMEX.MX", asset_type: :stock) }
  let(:day) { 3.days.ago.to_date }
  let(:from) { 30.days.ago.to_date }

  # DataBursatil answers with a close and an amount and nothing else, which is
  # what makes it the honest fixture for a partial bar.
  def stub_history(rows)
    stub_databursatil("/v2/historicos", rows)
  end

  describe "a close-only bar over an existing full row" do
    let!(:existing) do
      AssetPriceHistory.create!(
        asset_id: asset.id, date: day, interval: "1d",
        open: 70.0, high: 72.0, low: 69.0, close: 71.0, volume: 1_000_000,
        source: "Yahoo Finance", status: "confirmed"
      )
    end

    before { stub_history(day.to_s => [ 71.5, 5_000 ]) }

    it "updates the close and leaves the columns it has no value for" do
      described_class.call(asset: asset, from: from)

      existing.reload
      expect(existing.close.to_f).to eq(71.5)
      expect(existing.open.to_f).to eq(70.0)
      expect(existing.high.to_f).to eq(72.0)
      expect(existing.low.to_f).to eq(69.0)
      expect(existing.volume).to eq(1_000_000)
    end

    it "records that one provider's number replaced another's" do
      expect { described_class.call(asset: asset, from: from) }
        .to change { SystemLog.where(module_name: "sync").count }.by(1)

      expect(SystemLog.last.error_message).to eq("Yahoo Finance → DataBursatil/bmv")
    end
  end

  describe "overwrite: false" do
    let!(:existing) do
      AssetPriceHistory.create!(
        asset_id: asset.id, date: day, interval: "1d",
        close: 71.0, source: "Yahoo Finance", status: "confirmed"
      )
    end

    before { stub_history(day.to_s => [ 99.9, 5_000 ], (day - 1).to_s => [ 68.0, 4_000 ]) }

    it "adds the dates the asset lacks" do
      expect { described_class.call(asset: asset, from: from, overwrite: false) }
        .to change(AssetPriceHistory, :count).by(1)

      expect(AssetPriceHistory.find_by(asset_id: asset.id, date: day - 1).close.to_f).to eq(68.0)
    end

    it "leaves a date it already holds untouched, source and all" do
      described_class.call(asset: asset, from: from, overwrite: false)

      existing.reload
      expect(existing.close.to_f).to eq(71.0)
      expect(existing.source).to eq("Yahoo Finance")
    end
  end

  describe "the result" do
    before { stub_history(day.to_s => [ 71.5, 5_000 ]) }

    it "names the source that answered and what it wrote" do
      result = described_class.call(asset: asset, from: from)

      expect(result).to be_success
      expect(result.value!).to include(source: "DataBursatil/bmv", fetched: 1, written: 1, rejected: 0)
    end
  end

  describe "when no source serves the asset" do
    it "fails rather than reporting an empty success" do
      allow(DataSourceRegistry).to receive(:for_capability).and_return([])

      result = described_class.call(asset: asset, from: from)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_supported)
    end
  end
end
