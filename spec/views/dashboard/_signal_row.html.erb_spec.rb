require "rails_helper"

# The row dates a stale reading because Panorama's list is undated. Señales
# groups the same rows under HOY / AYER, so the row repeated what the heading
# above it had already said.
RSpec.describe "dashboard/_signal_row" do
  let(:asset) { create(:asset, :stock, symbol: "AAPL") }

  def render_row(observed_at:, **locals)
    observation = create(:technical_observation, asset: asset, observed_at: observed_at)
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
end
