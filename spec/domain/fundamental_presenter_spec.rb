require "rails_helper"

RSpec.describe FundamentalPresenter do
  let(:asset) { build(:asset, current_price: 189.43) }
  let(:fundamental) do
    build(:asset_fundamental, asset: asset, metrics: {
      "eps" => "6.07",
      "book_value" => "3.95",
      "revenue_per_share" => "25.23",
      "return_on_equity" => "1.5700",
      "beta" => "1.24",
      "sector" => "Technology"
    })
  end
  let(:presenter) { described_class.new(asset: asset, fundamental: fundamental) }

  describe "#pe_ratio" do
    it "computes live P/E from current_price and stored EPS" do
      expect(presenter.pe_ratio).to eq((189.43 / 6.07).round(2))
    end

    it "returns nil when EPS is zero" do
      fundamental.metrics["eps"] = "0"
      expect(presenter.pe_ratio).to be_nil
    end

    it "returns nil when current_price is nil" do
      asset.current_price = nil
      expect(presenter.pe_ratio).to be_nil
    end

    it "returns nil when EPS is missing" do
      fundamental.metrics.delete("eps")
      expect(presenter.pe_ratio).to be_nil
    end
  end

  describe "#pb_ratio" do
    it "computes live P/B from current_price and stored book value" do
      expect(presenter.pb_ratio).to eq((189.43 / 3.95).round(2))
    end

    it "returns nil when book_value is zero" do
      fundamental.metrics["book_value"] = "0"
      expect(presenter.pb_ratio).to be_nil
    end
  end

  describe "#ps_ratio" do
    it "computes live P/S from current_price and stored revenue per share" do
      expect(presenter.ps_ratio).to eq((189.43 / 25.23).round(2))
    end

    it "returns nil when revenue_per_share is missing" do
      fundamental.metrics.delete("revenue_per_share")
      expect(presenter.ps_ratio).to be_nil
    end
  end

  describe "#fcf_yield" do
    it "returns nil (Phase 10.1 feature)" do
      expect(presenter.fcf_yield).to be_nil
    end
  end

  describe "#metric" do
    it "returns a stored metric by key" do
      expect(presenter.metric(:beta)).to eq("1.24")
    end

    it "returns nil for unknown metric" do
      expect(presenter.metric(:nonexistent)).to be_nil
    end
  end

  describe "dynamic method access" do
    it "delegates unknown methods to stored metrics" do
      expect(presenter.return_on_equity).to eq("1.5700")
      expect(presenter.sector).to eq("Technology")
    end

    it "raises NoMethodError for truly unknown methods" do
      expect { presenter.completely_unknown! }.to raise_error(NoMethodError)
    end
  end

  describe "with nil fundamental" do
    let(:presenter) { described_class.new(asset: asset, fundamental: nil) }

    it "returns nil for computed metrics" do
      expect(presenter.pe_ratio).to be_nil
      expect(presenter.pb_ratio).to be_nil
      expect(presenter.ps_ratio).to be_nil
    end

    it "returns nil for stored metrics" do
      expect(presenter.metric(:beta)).to be_nil
    end
  end
end
