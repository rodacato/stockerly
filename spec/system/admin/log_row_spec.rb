require "rails_helper"

# The task name is what identifies a log entry. Sharing its line with a
# seconds-precision stamp cut it to "Yahoo Fi…" on a phone.
RSpec.describe "Registros row on a phone", type: :system, js: true do
  let!(:admin) { create(:user, :admin, email: "logs@test.com", password: "password123", onboarded_at: Time.current) }

  before do
    create(:portfolio, user: admin)
    create(:system_log, task_name: "Yahoo Finance Sync", module_name: "sync", severity: :warning, error_message: "Rate limit")
    visit login_path
    fill_in "Correo electrónico", with: "logs@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    page.driver.resize(390, 844)
    visit admin_logs_path
  end

  it "shows the whole task name" do
    expect(page).to have_content("Yahoo Finance Sync")

    overflow = page.evaluate_script(<<~JS)
      (() => { const el = [...document.querySelectorAll("li p")].find(p => p.textContent.trim() === "Yahoo Finance Sync");
               return el.scrollWidth - el.clientWidth; })()
    JS
    expect(overflow).to eq(0)
  end
end
