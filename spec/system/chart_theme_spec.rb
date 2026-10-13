require "rails_helper"

RSpec.describe "Chart theme changes", type: :system, js: true do
  let!(:user) { create(:user, email: "chart-theme@example.test", password: "password123", preferred_currency: "MXN", onboarded_at: Time.current) }

  it "repaints labels and series without losing the visible range" do
    portfolio = user.portfolio || create(:portfolio, user: user)
    portfolio.update!(inception_date: 5.days.ago.to_date)
    5.downto(0) do |day|
      create(:portfolio_snapshot, portfolio: portfolio, date: day.days.ago.to_date, currency: "MXN", total_value: 1000 + day)
    end
    visit login_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    visit portfolio_path
    expect(page).to have_css("[data-controller='chart'] canvas")

    before = chart_style
    page.execute_script("document.documentElement.classList.add('dark')")
    expect(page).to have_css("html.dark [data-controller='chart'] canvas")
    after = chart_style

    expect(after["text"].downcase).to eq("#94a3b8")
    expect(after["line"].downcase).to eq("#34d399")
    expect(after["text"]).not_to eq(before["text"])
    expect(after["range"]).to eq(before["range"])
  end

  def chart_style
    page.evaluate_script(<<~JS)
      (() => {
        const element = document.querySelector('[data-controller="chart"]');
        const controller = Stimulus.getControllerForElementAndIdentifier(element, "chart");
        return { text: controller.chart.options().layout.textColor,
                 line: controller.mainSeries.options().color,
                 range: controller.chart.timeScale().getVisibleLogicalRange() };
      })()
    JS
  end
end
