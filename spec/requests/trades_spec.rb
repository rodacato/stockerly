require "rails_helper"

RSpec.describe "Trades", type: :request do
  let!(:user) { create(:user, email: "trader@example.com", password: "password123") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL") }

  let(:valid_buy_params) do
    { trade: { asset_symbol: "AAPL", side: "buy", shares: "10", price_per_share: "150.0" } }
  end

  describe "GET /trades" do
    context "when authenticated" do
      before { login_as(user) }

      it "renders the trade history page" do
        get trades_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Trade History")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get trades_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "POST /trades" do
    before { login_as(user) }

    it "creates a buy trade and redirects with notice" do
      expect {
        post trades_path, params: valid_buy_params
      }.to change(Trade, :count).by(1)

      expect(response).to redirect_to(portfolio_path)
      follow_redirect!
      expect(response.body).to include("Trade executed successfully")
    end

    it "creates a sell trade when position has enough shares" do
      create(:position, portfolio: portfolio, asset: asset, shares: 10.0, avg_cost: 140.0, status: :open)

      expect {
        post trades_path, params: { trade: { asset_symbol: "AAPL", side: "sell", shares: "5", price_per_share: "160.0" } }
      }.to change(Trade, :count).by(1)

      expect(response).to redirect_to(portfolio_path)
    end

    it "redirects with alert on invalid params" do
      post trades_path, params: { trade: { asset_symbol: "", side: "buy", shares: "0", price_per_share: "0" } }

      expect(response).to redirect_to(portfolio_path)
      follow_redirect!
      expect(response.body).to include("alert")
    end

    it "redirects with alert on insufficient shares" do
      post trades_path, params: { trade: { asset_symbol: "AAPL", side: "sell", shares: "5", price_per_share: "150.0" } }

      expect(response).to redirect_to(portfolio_path)
    end

    context "with turbo_stream format" do
      it "responds with turbo_stream on success" do
        post trades_path, params: valid_buy_params, as: :turbo_stream

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("trade_history")
        expect(response.body).to include("Buy executed")
      end

      it "responds with turbo_stream error on failure" do
        post trades_path, params: { trade: { asset_symbol: "", side: "buy", shares: "0", price_per_share: "0" } }, as: :turbo_stream

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("flash_messages")
      end
    end
  end

  describe "GET /trades/:id/edit" do
    before { login_as(user) }

    let!(:trade) do
      create(:trade, portfolio: portfolio, asset: asset, side: :buy,
             shares: 10.0, price_per_share: 150.0, total_amount: 1500.0, executed_at: 2.days.ago)
    end

    it "returns turbo_stream with edit form" do
      get edit_trade_path(trade), as: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("Save")
      expect(response.body).to include("Cancel")
    end

    it "redirects when trade not found" do
      get edit_trade_path(id: 999999)
      expect(response).to redirect_to(trades_path)
    end
  end

  describe "PATCH /trades/:id" do
    before { login_as(user) }

    let!(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10.0, avg_cost: 150.0, status: :open) }
    let!(:trade) do
      create(:trade, portfolio: portfolio, asset: asset, position: position,
             side: :buy, shares: 10.0, price_per_share: 150.0, total_amount: 1500.0, executed_at: 2.days.ago)
    end

    it "updates trade and redirects with notice" do
      patch trade_path(trade), params: { trade: { shares: "15" } }

      expect(response).to redirect_to(trades_path)
      follow_redirect!
      expect(response.body).to include("Trade updated successfully")
      expect(trade.reload.shares).to eq(15.0)
    end

    it "returns turbo_stream on success" do
      patch trade_path(trade), params: { trade: { shares: "15" } }, as: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("Trade updated successfully")
    end

    it "rejects update on old trade" do
      trade.update_column(:executed_at, 31.days.ago)

      patch trade_path(trade), params: { trade: { shares: "15" } }

      expect(response).to redirect_to(trades_path)
      follow_redirect!
      expect(response.body).to include("Cannot edit trades older than 30 days")
    end
  end

  describe "DELETE /trades/:id" do
    before { login_as(user) }

    let!(:position) { create(:position, portfolio: portfolio, asset: asset, shares: 10.0, avg_cost: 150.0, status: :open) }
    let!(:trade) do
      create(:trade, portfolio: portfolio, asset: asset, position: position,
             side: :buy, shares: 10.0, price_per_share: 150.0, total_amount: 1500.0, executed_at: 2.days.ago)
    end

    it "soft-deletes the trade and redirects" do
      delete trade_path(trade)

      expect(response).to redirect_to(trades_path)
      follow_redirect!
      expect(response.body).to include("Trade deleted")
      expect(trade.reload.discarded?).to be true
    end

    it "returns turbo_stream removing the row" do
      delete trade_path(trade), as: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("remove")
    end

    it "rejects deletion of old trade" do
      trade.update_column(:executed_at, 31.days.ago)

      delete trade_path(trade)

      expect(response).to redirect_to(trades_path)
      follow_redirect!
      expect(response.body).to include("Cannot delete trades older than 30 days")
    end
  end
end
