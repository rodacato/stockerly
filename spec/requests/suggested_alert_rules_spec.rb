require "rails_helper"

RSpec.describe "Suggested alert rules on the empty state", type: :request do
  let!(:user) { create(:user, password: "password123") }
  let(:portfolio) { create(:portfolio, user: user) }
  let(:aapl) { create(:asset, symbol: "AAPL", asset_type: :stock, current_price: 190) }

  before { login_as(user) }

  context "with holdings and no rules" do
    before { create(:position, portfolio: portfolio, asset: aapl, shares: 12, status: :open) }

    it "proposes rules derived from what is held" do
      get alerts_path

      expect(response.body).to include("A partir de lo que ya tienes")
      expect(response.body).to include("AAPL")
    end

    it "explains what the indicator measures, which is the whole point of the block" do
      get alerts_path

      expect(response.body).to include("El RSI mide si un activo subió mucho muy rápido")
    end

    it "states the holding as the reason the suggestion is for this owner" do
      get alerts_path

      expect(response.body).to include("Tienes 12 títulos")
    end

    it "links each suggestion to the form with the whole rule prefilled" do
      get alerts_path

      expect(response.body).to include(CGI.escapeHTML(
        new_alert_path(asset_symbol: "AAPL", condition: "day_change_percent",
                       threshold_value: 5, window_days: nil)
      ))
    end

    it "prefills the form from a suggestion's link" do
      get new_alert_path(asset_symbol: "AAPL", condition: "rsi_overbought", threshold_value: 70)

      expect(response.body).to include("AAPL")
      expect(response.body).to include("70")
    end

    it "falls back to a safe condition when the link names one that does not exist" do
      get new_alert_path(asset_symbol: "AAPL", condition: "nonsense_condition")

      expect(response).to have_http_status(:ok)
    end
  end

  context "when there is nothing to suggest from" do
    it "still renders the empty state, without a suggestions block" do
      get alerts_path

      expect(response.body).to include("Todavía no tienes reglas")
      expect(response.body).not_to include("A partir de lo que ya tienes")
    end
  end

  context "when a rule already exists" do
    before do
      create(:position, portfolio: portfolio, asset: aapl, shares: 12, status: :open)
      create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :day_change_percent)
    end

    it "shows no suggestions at all, because the empty state is not rendered" do
      get alerts_path

      expect(response.body).not_to include("A partir de lo que ya tienes")
    end
  end
end
