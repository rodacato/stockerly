require "rails_helper"

# D112: the O/H/L/C/Vol strip pins the latest bar until the crosshair picks
# another, then goes back when the pointer leaves. Only a browser can prove it —
# the request specs cover the payload and the cells, and neither says the time
# the library reports matches the row the strip looks up.
RSpec.describe "Asset chart crosshair", type: :system, js: true do
  let!(:user) { create(:user, email: "crosshair@test.com", password: "password123", onboarded_at: Time.current) }
  let!(:asset) { create(:asset, symbol: "NVDA", currency: "USD") }

  # A distinct close per bar, so the strip cannot read as unchanged by accident.
  before do
    25.downto(0) do |days|
      create(:asset_price_history, asset: asset, date: days.days.ago.to_date, open: 100, high: 110, low: 90,
                                   close: 200 + days, volume: 1_500_000)
    end

    visit login_path
    fill_in "Correo electrónico", with: "crosshair@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    visit market_asset_path(asset.symbol, range: "1M")
  end

  def close_figure = all("[data-chart-target='stat']")[3].text

  # Viewport coordinates, because that is what the browser's mouse takes and
  # what the library reads back off the event.
  def plot_box
    page.evaluate_script(<<~JS)
      (() => {
        const plot = document.querySelector("[data-chart-target='canvas']");
        plot.scrollIntoView({ block: "center" });
        const box = plot.getBoundingClientRect();
        return { x: box.x, y: box.y, width: box.width, height: box.height };
      })()
    JS
  end

  def hover(fraction)
    box = plot_box

    page.driver.browser.mouse.move(x: (box["x"] + (box["width"] * fraction)).to_i,
                                   y: (box["y"] + (box["height"] / 2)).to_i)
  end

  it "paints the latest bar before anything is touched" do
    expect(close_figure).to eq("200.00")
  end

  it "reads the bar under the crosshair, then returns to the latest when it leaves" do
    hover(0.25)
    expect(page).to have_no_css("[data-chart-target='stat']", text: "200.00")
    early = close_figure

    hover(0.75)
    expect(page).to have_no_css("[data-chart-target='stat']", text: early)
    late = close_figure

    # The series runs oldest to newest and the closes descend with it, so a
    # strip that read the wrong row would not order them this way.
    expect(early.to_f).to be > late.to_f
    expect([ early, late ]).to all(match(/\A2[0-2]\d\.00\z/))

    page.driver.browser.mouse.move(x: 5, y: 5)
    expect(page).to have_css("[data-chart-target='stat']", text: "200.00")
  end

  # Ordering alone does not pin the row: an index shifted by one still reads
  # older-to-the-left. This lands the pointer on the coordinate the library
  # itself reports for one bar and asks the strip to name that bar's close.
  it "reads the bar the pointer is actually over, not its neighbour" do
    box = plot_box
    target = page.evaluate_script(<<~JS)
      (() => {
        const card = document.querySelector("[data-controller='chart']");
        const chart = window.Stimulus.getControllerForElementAndIdentifier(card, "chart");
        const bar = chart.mainSeries.data()[7];
        return { x: chart.chart.timeScale().timeToCoordinate(bar.time), close: bar.value };
      })()
    JS

    page.driver.browser.mouse.move(x: (box["x"] + target["x"]).to_i, y: (box["y"] + (box["height"] / 2)).to_i)

    expect(page).to have_css("[data-chart-target='stat']", text: format("%.2f", target["close"]))
  end

  it "leaves the figures the bar shares with every other one alone" do
    hover(0.25)

    expect(all("[data-chart-target='stat']").map(&:text).values_at(0, 1, 2, 4))
      .to eq([ "100.00", "110.00", "90.00", "1.5M" ])
  end
end
