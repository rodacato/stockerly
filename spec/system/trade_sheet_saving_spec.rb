require "rails_helper"

# D11's "Guardar y registrar otro", and the defect measuring it uncovered:
# saving used to leave the sheet open with the form still filled, which
# confirmed nothing and invited recording the same movement twice.
RSpec.describe "Saving from the trade sheet", type: :system, js: true do
  let(:user) do
    create(:user, email: "sheet@test.com", password: "password123",
                  preferred_currency: "MXN", onboarded_at: Time.current)
  end

  before do
    user.portfolio || create(:portfolio, user: user)
    create(:asset, :stock, symbol: "WALMEX", name: "Walmex", currency: "MXN", current_price: 70, sync_status: :active)
    create(:asset, :stock, symbol: "AMXL", name: "America Movil", currency: "MXN", current_price: 15, sync_status: :active)

    visit login_path
    fill_in "Correo electrónico", with: "sheet@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    visit assets_path
    click_link I18n.t("trades.new.titulo"), match: :first
    expect(page).to have_field("trade[asset_symbol]")
  end

  def fill_movement(symbol:, shares:, price:, currency: "MXN")
    fill_in "trade[asset_symbol]", with: symbol
    select currency, from: "trade[currency]"
    fill_in "trade[shares]", with: shares
    fill_in "trade[price_per_share]", with: price
  end

  describe "Guardar" do
    it "records the movement and closes the sheet" do
      fill_movement(symbol: "WALMEX", shares: "10", price: "70")

      expect { click_button I18n.t("trades.new.guardar") }.to change(Trade, :count).by(1)

      expect(page).to have_current_path(assets_path)
      expect(page).not_to have_css("dialog[open]")
    end
  end

  describe "Guardar y registrar otro" do
    it "records it and comes back to an empty sheet" do
      fill_movement(symbol: "WALMEX", shares: "10", price: "70")

      expect { click_button I18n.t("trades.new.guardar_y_otro") }.to change(Trade, :count).by(1)

      expect(page).to have_css("dialog[open]")
      expect(page).to have_field("trade[asset_symbol]", with: "")
    end

    # The flash lives behind the dialog, so a sheet that stays open has to
    # confirm inside itself or the save looks like nothing happened.
    it "confirms inside the sheet, where it can be seen" do
      fill_movement(symbol: "WALMEX", shares: "10", price: "70")
      click_button I18n.t("trades.new.guardar_y_otro")

      expect(page).to have_content(I18n.t("trades.new.guardado_otro"))
    end

    it "lets a second movement follow without reopening anything" do
      fill_movement(symbol: "WALMEX", shares: "10", price: "70")
      click_button I18n.t("trades.new.guardar_y_otro")
      expect(page).to have_field("trade[asset_symbol]", with: "")

      fill_movement(symbol: "AMXL", shares: "100", price: "15")

      expect { click_button I18n.t("trades.new.guardar") }.to change(Trade, :count).by(1)
      expect(Trade.includes(:asset).order(:created_at).map { |t| t.asset.symbol }).to eq(%w[WALMEX AMXL])
    end

    # Someone recording several sells is not switching back to buy each time.
    it "keeps the side you were working in" do
      create(:position, portfolio: user.portfolio, asset: Asset.find_by(symbol: "WALMEX"),
                        shares: 50, avg_cost: 60, status: :open)
      # The radio is sr-only, so the label is what a person actually clicks.
      find("label", text: I18n.t("trades.new.venta")).click
      fill_movement(symbol: "WALMEX", shares: "10", price: "70")

      click_button I18n.t("trades.new.guardar_y_otro")

      expect(page).to have_css("input[value='sell']:checked", visible: :all)
    end
  end
end
