require "rails_helper"

# The reference-index chip in "Contexto de mercado". An index that did not move
# has no direction, so it takes neither the gain colour nor the loss one.
RSpec.describe "Market detail — market context", type: :request do
  let(:user) { create(:user, email: "context@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", country: "US") }

  before { login_as(user) }

  def index_chip
    response.body[/<span class="font-mono text-sm font-semibold[^"]*">\s*[^<]*hoy/]
  end

  describe "GET /market/:symbol" do
    it "draws an index that rose in the gain colour" do
      create(:market_index, symbol: "SPX", name: "S&P 500", change_percent: 1.2)

      get market_asset_path(asset.symbol)

      expect(index_chip).to include("text-positive-fg")
      expect(index_chip).to include("+1.2%")
    end

    it "draws an index that fell in the loss colour" do
      create(:market_index, symbol: "SPX", name: "S&P 500", change_percent: -1.2)

      get market_asset_path(asset.symbol)

      expect(index_chip).to include("text-negative-fg")
      expect(index_chip).to include("−1.2%")
    end

    it "leaves an index that did not move uncoloured" do
      create(:market_index, symbol: "SPX", name: "S&P 500", change_percent: 0)

      get market_asset_path(asset.symbol)

      expect(index_chip).to include("text-fg-subtle")
      expect(index_chip).not_to include("text-positive-fg")
    end
  end
end
