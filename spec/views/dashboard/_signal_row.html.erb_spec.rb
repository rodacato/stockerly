require "rails_helper"

# The row dates a stale reading because Panorama's list is undated. Señales
# groups the same rows under HOY / AYER, so the row repeated what the heading
# above it had already said.
RSpec.describe "dashboard/_signal_row" do
  let(:asset) { create(:asset, :stock, symbol: "AAPL") }

  def render_row(observed_at:, observation_type: nil, **locals)
    attrs = { asset: asset, observed_at: observed_at, observation_type: observation_type }.compact
    observation = create(:technical_observation, **attrs)
    render partial: "dashboard/signal_row", locals: { observation: observation }.merge(locals)
  end

  it "dates a stale reading where nothing else does" do
    render_row(observed_at: 1.day.ago)

    expect(rendered).to include("ayer")
  end

  it "stays quiet where the list is already grouped by date" do
    render_row(observed_at: 1.day.ago, context: :senales)

    expect(rendered).not_to include("ayer")
  end

  it "says nothing about the age of a reading taken today" do
    render_row(observed_at: Time.current)

    expect(rendered).not_to include("hace")
  end

  describe "the arrow-and-colour explainer" do
    def fragment(type)
      render_row(observed_at: Time.current, observation_type: type)
      Nokogiri::HTML.fragment(rendered)
    end

    it "offers an ⓘ that decodes the convention, outside the link" do
      html = fragment("rsi_oversold_entered")

      expect(html.at_css("button[data-action='click->metric-tooltip#toggle'][aria-label*='AAPL']")).to be_present
      expect(html.css("a button")).to be_empty
      expect(rendered).to include("La flecha es el movimiento", "verde, compra; naranja, vende")
    end

    it "names the move for assistive tech instead of hiding the arrow" do
      arrow = fragment("rsi_oversold_entered").at_css("a svg")

      expect(arrow["aria-hidden"]).to be_nil
      expect(arrow["aria-label"]).to eq("Movimiento a la baja")
    end

    it "labels an upward move as such" do
      expect(fragment("ma200_crossed_above").at_css("a svg")["aria-label"]).to eq("Movimiento al alza")
    end

    it "offers no explainer on a reading that carries no action" do
      fragment("rsi_oversold_exited")

      expect(rendered).not_to include("metric-tooltip#toggle")
    end
  end
end
