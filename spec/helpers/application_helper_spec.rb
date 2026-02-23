require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#admin_nav_active?" do
    it "returns active classes when on the current page" do
      allow(helper).to receive(:current_page?).and_return(true)
      result = helper.admin_nav_active?("/admin/assets")
      expect(result).to include("bg-primary")
      expect(result).to include("text-white")
    end

    it "returns inactive classes when not on the current page" do
      allow(helper).to receive(:current_page?).and_return(false)
      result = helper.admin_nav_active?("/admin/assets")
      expect(result).to include("text-slate-600")
      expect(result).not_to include("bg-primary")
    end
  end

  describe "#app_nav_active?" do
    it "returns active classes when on the current page" do
      allow(helper).to receive(:current_page?).and_return(true)
      result = helper.app_nav_active?("/dashboard")
      expect(result).to include("text-primary")
      expect(result).to include("bg-primary/10")
    end

    it "returns inactive classes when not on the current page" do
      allow(helper).to receive(:current_page?).and_return(false)
      result = helper.app_nav_active?("/dashboard")
      expect(result).to include("text-slate-600")
      expect(result).not_to include("bg-primary/10")
    end
  end

  describe "#combined_data_status" do
    let(:asset) { build(:asset, price_updated_at: updated_at) }

    context "when market is closed" do
      let(:updated_at) { 1.minute.ago }

      it "returns :closed state regardless of data age" do
        status = helper.combined_data_status(asset, false)
        expect(status[:state]).to eq(:closed)
        expect(status[:label]).to eq("Market closed")
        expect(status[:dot_class]).to include("bg-slate-300")
      end
    end

    context "when market is open and data is fresh (<2 min)" do
      let(:updated_at) { 1.minute.ago }

      it "returns :live state" do
        status = helper.combined_data_status(asset, true)
        expect(status[:state]).to eq(:live)
        expect(status[:label]).to eq("Live")
        expect(status[:dot_class]).to include("bg-emerald-500")
      end
    end

    context "when market is open and data is delayed (2-15 min)" do
      let(:updated_at) { 5.minutes.ago }

      it "returns :delayed state" do
        status = helper.combined_data_status(asset, true)
        expect(status[:state]).to eq(:delayed)
        expect(status[:label]).to eq("Delayed")
        expect(status[:dot_class]).to include("bg-amber-500")
      end
    end

    context "when market is open and data is stale (>15 min)" do
      let(:updated_at) { 20.minutes.ago }

      it "returns :stale state with relative age label" do
        status = helper.combined_data_status(asset, true)
        expect(status[:state]).to eq(:stale)
        expect(status[:label]).to eq("20min ago")
        expect(status[:timestamp]).to be_within(1.second).of(updated_at)
      end
    end

    context "when market is open and data is hours old" do
      let(:updated_at) { 3.hours.ago }

      it "returns stale state with hours label" do
        status = helper.combined_data_status(asset, true)
        expect(status[:state]).to eq(:stale)
        expect(status[:label]).to eq("3h ago")
      end
    end

    context "when market is open and data is days old" do
      let(:updated_at) { 2.days.ago }

      it "returns stale state with days label" do
        status = helper.combined_data_status(asset, true)
        expect(status[:state]).to eq(:stale)
        expect(status[:label]).to eq("2d ago")
      end
    end

    context "when asset has never been synced" do
      let(:updated_at) { nil }

      it "returns :stale state with no data label" do
        status = helper.combined_data_status(asset, true)
        expect(status[:state]).to eq(:stale)
        expect(status[:label]).to eq("No data")
      end
    end
  end

  describe "#market_open_for" do
    it "returns true for crypto assets regardless of market status" do
      asset = build(:asset, :crypto)
      expect(helper.market_open_for(asset, { us: false, bmv: false, crypto: true })).to be true
    end

    it "returns BMV status for Mexican assets" do
      asset = build(:asset, :mexican)
      expect(helper.market_open_for(asset, { us: false, bmv: true, crypto: true })).to be true
      expect(helper.market_open_for(asset, { us: true, bmv: false, crypto: true })).to be false
    end

    it "returns US status for non-Mexican, non-crypto assets" do
      asset = build(:asset, asset_type: :stock, country: nil)
      expect(helper.market_open_for(asset, { us: true, bmv: false, crypto: true })).to be true
      expect(helper.market_open_for(asset, { us: false, bmv: true, crypto: true })).to be false
    end

    it "falls back to MarketHours when no status hash given" do
      asset = build(:asset, :crypto)
      expect(helper.market_open_for(asset, nil)).to be true
    end
  end
end
