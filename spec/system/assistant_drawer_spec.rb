require "rails_helper"

# #872's Definition of done, in a browser: from an asset's page, Velita opens
# the drawer, a suggestion is asked, the cards land at once and the prose
# streams into the same drawer. The provider is the one boundary stubbed.
RSpec.describe "Velita's drawer", type: :system, js: true do
  include ActiveJob::TestHelper

  let!(:user) { create(:user, email: "velita@test.com", password: "password123", onboarded_at: Time.current) }
  let!(:asset) { create(:asset, symbol: "NVDA", name: "NVIDIA", current_price: 110, price_updated_at: Time.current) }

  # The suite's cable adapter keeps broadcasts in memory; the browser needs
  # them delivered, as Solid Cable does in production.
  around do |example|
    original = ActionCable.server.pubsub
    ActionCable.server.instance_variable_set(:@pubsub, ActionCable::SubscriptionAdapter::Async.new(ActionCable.server))
    example.run
  ensure
    ActionCable.server.instance_variable_set(:@pubsub, original)
  end

  before do
    create(:technical_reading, asset: asset, readings: { "close" => 110.0, "rsi" => 72.4 })
    Integration.create!(provider_name: "Asistente", provider_type: "Assistant", connection_status: :connected, api_key_encrypted: "sk-test",
                        settings: { "base_url" => "https://api.anthropic.com", "model" => "claude-haiku-5-5", "show_velita" => true })
    stub_request(:post, "https://api.anthropic.com/v1/messages").to_return(
      status: 200, headers: { "Content-Type" => "text/event-stream" },
      body: %(event: content_block_delta\ndata: #{ { type: "content_block_delta", index: 0, delta: { type: "text_delta", text: "El RSI de NVDA está en 72.4 [2]." } }.to_json }\n\n)
    )

    visit login_path
    fill_in "Correo electrónico", with: "velita@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  def open_velita = find("a[aria-label='#{I18n.t("assistant.launcher.abrir")}']").click

  it "answers a suggestion about the asset inside the drawer" do
    visit market_asset_path("NVDA")
    open_velita

    expect(page).to have_css("dialog.assistant-sheet[open]")
    expect(page).to have_text(I18n.t("assistant.questions.new.sobre", symbol: "NVDA"))
    expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all)

    click_button I18n.t("assistant.questions.new.sugerencias.activo.rsi", symbol: "NVDA")

    within("dialog.assistant-sheet") do
      expect(page).to have_text("RSI (14) · NVDA")
      expect(page).to have_no_css("#assistant_suggestions")
    end

    perform_enqueued_jobs

    within("dialog.assistant-sheet") do
      expect(page).to have_text("El RSI de NVDA está en 72.4 [2].")
      expect(page).to have_text(I18n.t("assistant.questions.answer.no_es_recomendacion"))
    end
  end

  it "leaves the page usable on a desktop, as a side panel" do
    page.current_window.resize_to(1280, 900)
    visit dashboard_path
    open_velita

    expect(page).to have_css("dialog.assistant-sheet[open]")
    expect(page.evaluate_script("document.querySelector('dialog.assistant-sheet').matches(':modal')")).to be(false)
  end

  it "closes on its X and takes the URL back with it" do
    visit dashboard_path
    open_velita
    expect(page).to have_current_path(assistant_path(from: "panorama"))

    find("button[aria-label='#{I18n.t("assistant.questions.new.cerrar")}']").click

    expect(page).to have_no_css("dialog.assistant-sheet[open]")
    expect(page).to have_current_path(dashboard_path)
  end
end
