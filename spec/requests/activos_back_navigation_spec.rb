require "rails_helper"

# The screens Activos reaches through its foot-of-list rows carry a way back
# on a phone, the way the settings sub-screens do, instead of the root bar.
RSpec.describe "Activos sub-screens › way back", type: :request do
  let(:user) { create(:user, preferred_currency: "USD", onboarded_at: Time.current) }

  before do
    create(:portfolio, user: user)
    login_as(user)
  end

  def page_body = Capybara.string(response.body)

  def back_link_to(path)
    "header a[aria-label='Regresar'][href='#{path}']"
  end

  it "leads Tracked, Historial and the importer back to Activos" do
    [ tracked_assets_path, positions_path, new_trade_import_path ].each do |screen|
      get screen

      expect(page_body).to have_css(back_link_to(assets_path)), screen
      expect(page_body).to have_no_css("header a[aria-label='Ir al Panorama']"), screen
    end
  end

  it "keeps the tab the sub-screens belong to lit" do
    get new_trade_import_path
    expect(page_body).to have_css("a[aria-current='page']", text: "Activos")

    get totp_enrollment_path
    expect(page_body).to have_css("a[aria-current='page']", text: "Ajustes")
  end

  it "leads the import review back to the file picker" do
    create(:asset, :etf, symbol: "VT", currency: "USD")
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2025, 12, 1), rate: 18.2293, source: "banxico")

    post preview_trade_import_path, params: { contenido: "asset_symbol,side,shares,price_per_share,executed_at,external_id,currency\nVT,buy,2.0,100.0,2025-12-08,order-1,USD" }

    expect(page_body).to have_css(back_link_to(new_trade_import_path))
  end
end
