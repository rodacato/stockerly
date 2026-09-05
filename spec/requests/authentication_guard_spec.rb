require "rails_helper"

RSpec.describe "Authentication guard", type: :request do
  it "says why it sent you to login, rather than dropping you there silently" do
    get dashboard_path

    expect(flash[:alert]).to eq("Inicia sesión para continuar.")
  end

  it "redirects /dashboard to login when not authenticated" do
    get dashboard_path
    expect(response).to redirect_to(login_path)
  end

  it "redirects /portfolio to login when not authenticated" do
    get portfolio_path
    expect(response).to redirect_to(login_path)
  end

  it "redirects /alerts to login when not authenticated" do
    get alerts_path
    expect(response).to redirect_to(login_path)
  end

  it "redirects /settings/account to login when not authenticated" do
    get edit_account_settings_path
    expect(response).to redirect_to(login_path)
  end
end
