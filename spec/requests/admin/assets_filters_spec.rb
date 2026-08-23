require "rails_helper"

# Regression: row actions dropped the :page param and bounced back to page 1.
# A sync/toggle/delete must redirect to the same page you were on.
RSpec.describe "Admin Assets — row actions preserve the current page", type: :request do
  let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.") }

  before { login_as(admin) }

  it "keeps ?page= when toggling status" do
    patch toggle_status_admin_asset_path(asset), params: { page: 2 }

    expect(response).to redirect_to(admin_assets_path(page: "2"))
  end

  it "keeps ?page= and filters when triggering a sync" do
    post trigger_sync_admin_asset_path(asset), params: { page: 3, status: "active" }

    expect(response).to redirect_to(admin_assets_path(page: "3", status: "active"))
  end
end
