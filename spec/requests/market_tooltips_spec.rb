require "rails_helper"

RSpec.describe "Market Asset Metric Tooltips", type: :request do
  let!(:user) { create(:user, email: "tooltip@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 227.44, country: "US") }
  let!(:fundamental) do
    create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
      metrics: { "eps" => "6.07", "beta" => "1.24", "pe_ratio" => "31.25", "book_value" => "3.95" })
  end

  before { login_as(user) }

  describe "tooltip markup" do
    before { get market_asset_path(asset.symbol) }

    it "renders metric-tooltip Stimulus controller on cards" do
      expect(response.body).to include('data-controller="metric-tooltip"')
    end

    it "renders tooltip popover target" do
      expect(response.body).to include('data-metric-tooltip-target="popover"')
    end

    it "renders info toggle button with correct action" do
      expect(response.body).to include('data-action="click->metric-tooltip#toggle"')
    end

    it "renders close button with correct action" do
      expect(response.body).to include('data-action="click->metric-tooltip#close"')
    end

    it "renders educational content sections" do
      expect(response.body).to include("What it measures")
      expect(response.body).to include("How to interpret")
    end

    it "renders disclaimer in tooltip footer" do
      expect(response.body).to include("Financial data is informational only")
    end

    it "renders metric definition context guidance" do
      pe_def = MetricDefinitions.find(:pe_ratio)
      expect(response.body).to include(pe_def.context_guidance)
    end

    it "renders school icon in tooltip header" do
      expect(response.body).to include("school")
    end
  end
end
