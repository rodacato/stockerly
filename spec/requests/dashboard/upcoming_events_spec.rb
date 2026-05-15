require "rails_helper"

RSpec.describe "Dashboard — Upcoming Events (#29 JTBD #3)", type: :request do
  let(:user) { create(:user, email: "cetes-holder@example.com", password: "password123", preferred_currency: "MXN") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:cetes) { create(:asset, :fixed_income, symbol: "CETES_28D", name: "CETES 28 Days") }

  before { login_as(user) }

  describe "GET /dashboard" do
    context "with fixed-income positions approaching maturity" do
      before do
        create(:position, portfolio: portfolio, asset: cetes, shares: 100, avg_cost: 9.85, maturity_date: 5.days.from_now.to_date)
      end

      it "renders the Upcoming Events section with descriptive copy" do
        get dashboard_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Upcoming Events")
        expect(response.body).to include("CETES_28D")
        expect(response.body).to include("expires in 5 days")
      end

      it "does NOT render prescriptive action copy (ADR-001)" do
        get dashboard_path
        body = response.body
        expect(body).not_to match(/consider reinvest/i)
        expect(body).not_to match(/buy more|sell now/i)
        expect(body).not_to match(/you should/i)
      end
    end

    context "without fixed-income positions" do
      it "does not render the Upcoming Events section at all (no empty card)" do
        get dashboard_path
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Upcoming Events")
      end
    end

    context "with an expired CETES position" do
      it "does not list expired positions (past-maturity is not 'upcoming')" do
        create(:position, portfolio: portfolio, asset: cetes, shares: 100, avg_cost: 9.85, maturity_date: 3.days.ago.to_date)
        get dashboard_path
        expect(response.body).not_to include("Upcoming Events")
      end
    end
  end
end
