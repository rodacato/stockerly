require "rails_helper"

# ADR-032: each catalogued point records its event, with the origin its call
# to action carried. The switch is on throughout; Usage's own spec covers off.
RSpec.describe "Usage instrumentation", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current) }
  let!(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL", name: "Apple Inc.", current_price: 190, price_updated_at: Time.current) }

  before do
    SiteConfig.set(Usage::SWITCH, true)
    login_as(user)
  end

  def recorded(name) = UsageEvent.where(name: name).map { |event| [ event.screen, event.properties ] }

  def connect_velita
    Integration.create!(provider_name: "Asistente", provider_type: "Assistant", connection_status: :connected, api_key_encrypted: "sk-test",
                        settings: { "base_url" => "https://api.anthropic.com", "model" => "claude-haiku-5-5", "show_velita" => true })
  end

  describe "rule suggestions" do
    before { create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open) }

    it "records each suggestion the empty state shows, and carries via to the form" do
      get alerts_path

      expect(recorded("rule_suggestion.shown")).to include([ "reglas", { "condition" => "day_change_percent" } ])
      expect(response.body).to include("via=rule_suggestion")
      expect(AppOpen.where(path: "/alerts").sum(:count)).to eq(1)
    end

    it "says a rule came from a suggestion only when it did" do
      get new_alert_path(asset_symbol: "AAPL", condition: "price_crosses_above", via: "rule_suggestion")
      expect(response.body).to match(/name="via"[^>]*value="rule_suggestion"/)

      post alerts_path, params: { via: "rule_suggestion", alert: { asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 200.0 } }
      post alerts_path, params: { alert: { asset_symbol: "AAPL", condition: "price_crosses_below", threshold_value: 100.0 } }

      expect(recorded("rule.created").map(&:last)).to eq([ { "via" => "rule_suggestion" }, { "via" => "direct" } ])
    end
  end

  describe "the assistant" do
    before { connect_velita }

    it "records the suggestions it offered and how each question was asked" do
      get assistant_path(from: "senales")
      expect(recorded("assistant.suggestion_shown")).to eq([ [ "senales", {} ] ])

      post assistant_questions_path, params: { via: "suggestion", question: { question: "¿Qué dicen las señales?", token: "t1", screen: "senales" } }
      post assistant_questions_path, params: { via: "retry", question: { question: "¿Qué dicen las señales?", token: "t1", screen: "senales" } }
      post assistant_questions_path, params: { via: "typed", question: { question: "¿Y el IPC?", token: "t1", screen: "senales" } }

      expect(recorded("question.sent").map { |_, props| props["via"] }).to eq(%w[suggestion retry typed])
    end

    it "records a ? that brought the question, and keeps its origin on the form" do
      get assistant_path(from: "panorama", q: "Patrimonio", via: "help", figure: "patrimonio")

      expect(recorded("help.ask_velita")).to eq([ [ "panorama", { "figure" => "patrimonio" } ] ])
      expect(response.body).to match(/name="via"[^>]*value="help"/)
    end
  end

  describe "the asset page" do
    it "records where it was opened from, and not a change of chart range" do
      get market_asset_path("AAPL", from: "senales")
      get market_asset_path("AAPL")
      get market_asset_path("AAPL", range: "1Y")

      expect(recorded("asset.opened").map { |_, props| props["from"] }).to eq(%w[senales direct])
    end

    it "lets the browser report a headline opened, and nothing the catalogue keeps server-side" do
      create(:news_article, related_ticker: "AAPL", title: "Apple beats", source: "Bloomberg", published_at: 2.hours.ago, url: "https://example.com/a")
      get market_asset_path("AAPL")
      expect(response.body).to include(usage_events_path("news.opened", screen: "activo"))

      post usage_events_path("news.opened", screen: "activo")
      expect(response).to have_http_status(:no_content)
      post usage_events_path("trade.created", seconds: 1)
      expect(response).to have_http_status(:unprocessable_content)

      expect(UsageEvent.pluck(:name).tally).to eq("asset.opened" => 1, "news.opened" => 1)
    end
  end

  describe "a trade" do
    include ActiveSupport::Testing::TimeHelpers

    it "records the seconds from opening the sheet to saving it" do
      opened = Time.current.to_i
      travel_to(Time.zone.at(opened + 25)) do
        post trades_path, params: { opened_at: opened, trade: { asset_symbol: "AAPL", side: "buy", shares: "10", price_per_share: "150.0" } }
      end

      expect(recorded("trade.created")).to eq([ [ "movimiento", { "seconds" => 25 } ] ])
    end

    it "says nothing about a sheet left open for more than an hour" do
      post trades_path, params: { opened_at: 2.hours.ago.to_i, trade: { asset_symbol: "AAPL", side: "buy", shares: "10", price_per_share: "150.0" } }

      expect(recorded("trade.created")).to be_empty
    end
  end

  it "counts opens of Señales whatever the switch says" do
    SiteConfig.set(Usage::SWITCH, false)

    get signals_path

    expect(AppOpen.where(path: "/signals").sum(:count)).to eq(1)
    expect(UsageEvent.count).to eq(0)
  end

  it "records Velita's new colour" do
    connect_velita

    patch appearance_settings_assistant_path, params: { velita_colour: "cian" }
    patch appearance_settings_assistant_path, params: { velita_colour: "verde" }

    expect(recorded("velita.colour_changed")).to eq([ [ "ajustes", { "colour" => "cian" } ] ])
  end
end
