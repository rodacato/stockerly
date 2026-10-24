require "rails_helper"

# A suggestion is a promise: tapping it must bring the card it names, or the
# drawer opens on an answer with nothing to stand on (D166, ADR-031 §2).
RSpec.describe VelitaHelper, type: :helper do
  include ActiveSupport::Testing::TimeHelpers

  def kinds(question, symbol: nil) = Assistant::Domain::ContextSelector.call(question: question, symbol: symbol).map { |card| [ card.kind, card.title ] }

  it "keeps every Hoy suggestion answerable from the glossary" do
    expected = [ "Contra CETES", "CETES a 28 días", I18n.t("dashboard.ayuda.earnings.titulo") ]

    helper.assistant_suggestions(from: "panorama", symbol: nil, seen: %w[vs_cetes earnings]).zip(expected).each do |suggestion, title|
      expect(kinds(suggestion)).to include([ "glossary", title ]), "«#{suggestion}» did not retrieve «#{title}»"
    end
  end

  describe "on an asset's page" do
    let!(:asset) { create(:asset, symbol: "NVDA", name: "NVIDIA", current_price: 110, price_updated_at: Time.current) }

    before do
      create(:asset_fundamental, asset: asset, metrics: { "fifty_two_week_low" => "90.5", "fifty_two_week_high" => "130.25" })
      create(:technical_reading, asset: asset, readings: { "close" => 110.0, "rsi" => 72.4 })
      create(:news_article, related_ticker: "NVDA", title: "Nvidia reporta", published_at: 1.hour.ago)
    end

    it "brings the card each suggestion names" do
      rsi, range, headlines = helper.assistant_suggestions(from: "activos", symbol: "NVDA")

      expect(kinds(rsi, symbol: "NVDA").map(&:first)).to eq(%w[glossary reading])
      expect(kinds(range, symbol: "NVDA").map(&:first)).to eq(%w[range])
      expect(kinds(headlines, symbol: "NVDA").map(&:first)).to eq(%w[headlines])
    end
  end

  it "suggests nothing on a screen with no drawn suggestions" do
    expect(helper.assistant_suggestions(from: "reglas", symbol: nil)).to be_empty
  end
  describe "an answer's citations (D171)" do
    let(:message) do
      AssistantMessage.new(id: 7, answer: "Sube <b>0.6</b> [1] y cae [3].",
                           cards: [ { "kind" => "market", "title" => "Contexto de mercado" } ])
    end

    it "links a citation to its card and leaves one with no card as text" do
      html = Nokogiri::HTML.fragment(helper.assistant_answer_html(message))

      expect(html.css("a").map { |link| [ link.text, link["href"], link["aria-label"] ] })
        .to eq([ [ "[1]", "#assistant_card_7_1", "Fuente 1: Contexto de mercado" ] ])
      expect(html.text).to include("[3]")
    end

    it "escapes the prose around the links" do
      expect(helper.assistant_answer_html(message)).to include("&lt;b&gt;0.6&lt;/b&gt;")
    end
  end

  describe "an answer's Markdown" do
    def render(answer)
      Nokogiri::HTML.fragment(helper.assistant_answer_html(
        AssistantMessage.new(id: 7, answer: answer, cards: [ { "kind" => "market", "title" => "Contexto" } ])
      ))
    end

    it "renders paragraphs, a list and bold instead of showing the syntax" do
      html = render("## Resumen\n\n**NVDA** sube [1].\nTus posiciones:\n- AAPL\n- **VOO** [1]\n\nNada más.")

      expect(html.css("p").map(&:text)).to eq([ "Resumen", "NVDA sube [1].Tus posiciones:", "Nada más." ])
      expect(html.css("p br").size).to eq(1)
      expect(html.css("li").map(&:text)).to eq([ "AAPL", "VOO [1]" ])
      expect(html.css("strong").map(&:text)).to eq(%w[NVDA VOO])
      expect(html.css("li a").map(&:text)).to eq([ "[1]" ])
      expect(html.text).not_to include("**", "##", "- ")
    end

    it "leaves a bold still being streamed as text until it closes" do
      expect(render("Sube **NVD").text).to eq("Sube **NVD")
    end

    it "keeps markup inside the Markdown escaped" do
      html = render("**<script>x</script>**")

      expect(html.css("script")).to be_empty
      expect(html.css("strong").text).to eq("<script>x</script>")
    end
  end

  it "says only the hour of a question asked today, and the day of an older one" do
    travel_to Time.zone.local(2026, 10, 22, 18, 30) do
      expect(helper.assistant_asked_at(Time.zone.local(2026, 10, 22, 9, 5))).to eq("09:05")
      expect(helper.assistant_asked_at(Time.zone.local(2026, 10, 20, 9, 5))).to eq("20 oct · 09:05")
    end
  end

  # ADR-031 §7, D173: the figure beside an answer says what the pipeline is doing, nothing else.
  describe "Velita's state and colour" do
    def message(**attributes) = AssistantMessage.new(question: "¿Qué es el RSI?", **attributes)

    it "follows the message through the pipeline" do
      expect(helper.velita_state(message(status: :pending))).to eq(:searching)
      expect(helper.velita_state(message(status: :streaming))).to eq(:citing)
      expect(helper.velita_state(message(status: :streaming, answer: "Mide"))).to eq(:speaking)
      expect(helper.velita_state(message(status: :answered, answer: "Mide"))).to eq(:idle)
      expect(helper.velita_state(message(status: :discarded))).to eq(:no_data)
      expect(helper.velita_state(message(status: :failed))).to eq(:offline)
    end

    it "is grey when she cannot answer, whatever colour was picked" do
      expect(helper.velita_paint(:offline, "naranja")).to eq([ "text-fg-subtle", "fill-fg-inverse" ])
    end

    it "gives a light body dark eyes, in both themes" do
      expect(helper.velita_paint(:idle, "cielo").last).to eq("fill-fg-default dark:fill-fg-inverse")
      expect(helper.velita_paint(:idle, "indigo").last).to eq("fill-fg-inverse")
    end
  end
end
