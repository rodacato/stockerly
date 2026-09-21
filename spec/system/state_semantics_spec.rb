require "rails_helper"

# The server can render the state once; keeping it true afterwards is the
# controller's job, and neither controller used to have one to keep.
RSpec.describe "State semantics in the browser", type: :system, js: true do
  let!(:admin) do
    create(:user, :admin, email: "estado@test.com", password: "password123", onboarded_at: Time.current)
  end

  before do
    create(:portfolio, user: admin)
    visit login_path
    fill_in "Correo electrónico", with: "estado@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "says a disclosure is open once it is" do
    create(:system_log, :error, task_name: "Yahoo Finance Sync", error_message: "Rate limit")
    visit admin_logs_path
    trigger = find("[data-reveal-target='trigger']")

    expect(trigger["aria-expanded"]).to eq("false")

    trigger.click

    expect(page).to have_content("Rate limit")
    expect(trigger["aria-expanded"]).to eq("true")
  end

  it "turns the chevron with it" do
    create(:system_log, :error, error_message: "Rate limit")
    visit admin_logs_path
    trigger = find("[data-reveal-target='trigger']")
    rotation = -> { page.evaluate_script("getComputedStyle(document.querySelector(\"[data-reveal-target='trigger'] svg\")).rotate") }

    expect(rotation.call).to eq("none")

    trigger.click

    expect(rotation.call.to_f).to be > 0
  end

  it "moves a notification switch's announced state with its paint" do
    create(:alert_preference, user: admin, email_digest: true, urgent_email: false)
    visit settings_path
    digest = find("[role='switch'][aria-label='#{I18n.t("settings.show.digest")}']")

    expect(digest["aria-checked"]).to eq("true")

    digest.click

    expect(digest["aria-checked"]).to eq("false")
    expect(admin.alert_preference.reload.email_digest).to be(false)
  end
end
