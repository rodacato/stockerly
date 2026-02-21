require "rails_helper"

RSpec.describe "Authentication guard", type: :request do
  it "redirects /dashboard to login when not authenticated" do
    get dashboard_path
    expect(response).to redirect_to(login_path)
  end

  it "redirects /market to login when not authenticated" do
    get market_path
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

  it "redirects /earnings to login when not authenticated" do
    get earnings_path
    expect(response).to redirect_to(login_path)
  end

  it "redirects /profile to login when not authenticated" do
    get profile_path
    expect(response).to redirect_to(login_path)
  end
end
