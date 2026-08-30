require "rails_helper"

# Issue 428. The projection is a live client-side reading, like the running
# total beside it, so a real browser is the only place it can be proven. The
# arithmetic is deliberately not duplicated in Ruby — see the PR.
RSpec.describe "Registrar movimiento — proyección del costo promedio", type: :system, js: true do
  let!(:user) { create(:user, email: "dca@test.com", password: "password123", onboarded_at: Time.current, preferred_currency: "MXN") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL", name: "Apple", currency: "USD", current_price: 150) }

  def sign_in
    visit login_path
    fill_in "Correo electrónico", with: "dca@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  def open_sheet_for(symbol)
    visit new_trade_path(symbol: symbol)
    select "USD", from: "trade[currency]"
  end

  def projection = find("[data-trade-sheet-target='projection']", visible: :all)

  before { sign_in }

  context "with a position already held" do
    before { create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 200.0) }

    it "states where the average lands, and does not say what to do about it" do
      open_sheet_for("AAPL")
      fill_in "trade[shares]", with: "10"
      fill_in "trade[price_per_share]", with: "100"

      # (10*200 + 10*100) / 20 = 150
      expect(projection).to have_text("USD 200.00")
      expect(projection).to have_text("USD 150.00")
      expect(projection.text).not_to match(/oportunid|conviene|recomend|deberías/i)
    end

    # The DoD's condition: buying above the average moves it up, and the block
    # must not hide that by only being shown when the news is good.
    it "shows the average moving up when the buy is above it" do
      open_sheet_for("AAPL")
      fill_in "trade[shares]", with: "10"
      fill_in "trade[price_per_share]", with: "300"

      # (10*200 + 10*300) / 20 = 250
      expect(projection).to have_text("USD 250.00")
    end

    it "handles a fractional position" do
      Position.last.update!(shares: 2.5, avg_cost: 100.0)
      open_sheet_for("AAPL")
      fill_in "trade[shares]", with: "2.5"
      fill_in "trade[price_per_share]", with: "200"

      expect(projection).to have_text("USD 150.00")
    end

    it "stays hidden until a quantity is entered" do
      open_sheet_for("AAPL")
      fill_in "trade[price_per_share]", with: "100"

      expect(page).to have_no_css("[data-trade-sheet-target='projection']", visible: :visible)
    end

    # Averaging a USD price against a USD basis is arithmetic; against an MXN
    # basis it is adding two units.
    it "disappears when the sheet is entering a different currency than the asset" do
      open_sheet_for("AAPL")
      fill_in "trade[shares]", with: "10"
      fill_in "trade[price_per_share]", with: "100"
      expect(page).to have_css("[data-trade-sheet-target='projection']", visible: :visible)

      select "MXN", from: "trade[currency]"
      fill_in "trade[price_per_share]", with: "100"

      expect(page).to have_no_css("[data-trade-sheet-target='projection']", visible: :visible)
    end

    # The symbol field is free text, so the sheet can stop being about the
    # position it was opened for.
    it "disappears when the symbol is changed to something else" do
      open_sheet_for("AAPL")
      fill_in "trade[shares]", with: "10"
      fill_in "trade[price_per_share]", with: "100"
      expect(page).to have_css("[data-trade-sheet-target='projection']", visible: :visible)

      fill_in "trade[asset_symbol]", with: "MSFT"

      expect(page).to have_no_css("[data-trade-sheet-target='projection']", visible: :visible)
    end

    it "persists nothing by being used" do
      open_sheet_for("AAPL")

      expect {
        fill_in "trade[shares]", with: "10"
        fill_in "trade[price_per_share]", with: "100"
        expect(page).to have_css("[data-trade-sheet-target='projection']", visible: :visible)
      }.not_to(change { [ Trade.count, Position.last.avg_cost, Position.last.shares ] })
    end
  end

  it "is absent for an asset that is only watched" do
    open_sheet_for("AAPL")
    fill_in "trade[shares]", with: "10"
    fill_in "trade[price_per_share]", with: "100"

    expect(page).to have_no_css("[data-trade-sheet-target='projection']", visible: :visible)
  end

  it "is absent for fixed income, which has no average to move" do
    cete = create(:asset, :fixed_income, symbol: "CETE28", currency: "MXN", current_price: 9.8)
    create(:position, portfolio: portfolio, asset: cete, shares: 100, avg_cost: 9.5)

    visit new_trade_path(symbol: "CETE28")
    fill_in "trade[shares]", with: "100"
    fill_in "trade[price_per_share]", with: "9.7"

    expect(page).to have_no_css("[data-trade-sheet-target='projection']", visible: :visible)
  end
end
