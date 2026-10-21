require "rails_helper"

RSpec.describe "Tu plan", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current) }
  let!(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:params) { { stocks_share: "50", crypto_share: "20", fixed_income_share: "30", monthly_contribution: "5000" } }

  before { login_as(user) }

  it "shows an empty form with nothing prefilled" do
    get plan_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Los tres tipos deben sumar 100%.")
    expect(response.body).not_to match(/value="50"/)
  end

  it "saves a plan and shows it back as summing to 100" do
    patch plan_path, params: { plan: params }

    expect(response).to redirect_to(plan_path)
    expect(portfolio.reload.plan).to have_attributes(stocks_share: 50, crypto_share: 20, fixed_income_share: 30)

    get plan_path

    expect(response.body).to include("Suman 100%.")
    expect(response.body).to match(/value="50"/)
  end

  it "says how far from 100 the shares are and keeps what was typed" do
    patch plan_path, params: { plan: params.merge(fixed_income_share: "25") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Suman 95%, y deben sumar 100%. Faltan 5 puntos.")
    expect(response.body).to match(/value="25"/)
    expect(Plan.count).to eq(0)
  end

  it "is reachable from the Ajustes hub" do
    get settings_path

    expect(response.body).to include(plan_path)
  end

  it "needs a session" do
    reset!

    get plan_path

    expect(response).to redirect_to(login_path)
  end
end
