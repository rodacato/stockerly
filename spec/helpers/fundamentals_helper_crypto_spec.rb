require "rails_helper"

RSpec.describe FundamentalsHelper, type: :helper do
  describe "#summary_metrics_for" do
    it "returns CRYPTO_SUMMARY_METRICS for crypto assets" do
      asset = build(:asset, asset_type: :crypto)
      metrics = helper.summary_metrics_for(asset)

      expect(metrics).to eq(FundamentalsHelper::CRYPTO_SUMMARY_METRICS)
      expect(metrics).to include(:circulating_supply, :fully_diluted_valuation, :ath_price)
    end

    it "returns SUMMARY_METRICS for stock assets" do
      asset = build(:asset, asset_type: :stock)
      metrics = helper.summary_metrics_for(asset)

      expect(metrics).to eq(FundamentalsHelper::SUMMARY_METRICS)
      expect(metrics).to include(:pe_ratio, :roe, :eps)
    end
  end
end
