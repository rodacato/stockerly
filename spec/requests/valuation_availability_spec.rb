require "rails_helper"

RSpec.describe "Valuation availability", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }
  let(:portfolio) { create(:portfolio, user: user) }
  let(:asset) { create(:asset, :mexican, current_price: nil) }

  before do
    create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100)
    login_as(user)
  end

  it "does not report a missing quote as zero patrimony or a total loss on Panorama" do
    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("shared.valuation_notice.titulo"))
    expect(response.body).not_to include("−100.0%", "MXN 0")
  end

  [ :portfolio_path, :assets_path ].each do |route|
    it "absents incomplete composites on #{route}" do
      get public_send(route)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("shared.valuation_notice.titulo"))
      expect(response.body).not_to include("−100.0%", "MXN 0")
    end
  end

  it "keeps the position tab readable without inventing a total loss" do
    get market_asset_path(asset.symbol)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("market.position_summary.sin_precio"))
    expect(response.body).not_to include("−100.0%")
    expect(response.body).to include("MXN 1,000.00")
  end

  it "distinguishes stale quotes from a provider error" do
    asset.update!(current_price: 100, price_updated_at: 1.hour.ago)
    get market_asset_path(asset.symbol)
    expect(response.body).to include(I18n.t("components.asset_price.desactualizado"))

    asset.update!(last_sync_error: "Synthetic provider failure")
    get market_asset_path(asset.symbol)
    expect(response.body).to include(I18n.t("components.asset_price.error_proveedor"))
    expect(response.body).not_to include(I18n.t("components.asset_price.desactualizado"))
  end

  it "distinguishes a real zero value from an unknown quote" do
    asset.update!(current_price: 0)
    get dashboard_path

    expect(response.body).to include("MXN 0")
    expect(response.body).not_to include(I18n.t("shared.valuation_notice.titulo"))
  end

  it "does not report a flat day when yesterday's baseline is missing" do
    asset.update!(current_price: 100)
    get dashboard_path

    expect(response.body).to include(I18n.t("shared.day_change.sin_base"))
    expect(response.body).not_to include("0.0% hoy")
  end
end
