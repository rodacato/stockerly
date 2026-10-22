require "rails_helper"

# ADR-031: the Señales list for the assistant. What is held shows only when
# the caller may say what the owner holds.
RSpec.describe Trading::Queries::Signals do
  let(:user) { create(:user, onboarded_at: Time.current) }
  let(:held) { create(:asset, symbol: "NVDA") }
  let(:watched) { create(:asset, symbol: "ASML") }

  before do
    portfolio = user.portfolio || create(:portfolio, user: user)
    create(:position, portfolio: portfolio, asset: held, shares: 10, status: :open)
    create(:watchlist_item, user: user, asset: watched)
    create(:watchlist_item, user: user, asset: held)
    create(:technical_observation, asset: held)
    create(:technical_observation, :ma200_crossed_below, asset: watched)
  end

  it "reads only what is watched and not held when holdings may not be shared" do
    expect(described_class.call(include_held: false, user: user).pluck(:symbol)).to eq(%w[ASML])
  end

  it "reads what is held too, saying which, when they may" do
    readings = described_class.call(include_held: true, user: user)

    expect(readings.to_h { |row| [ row[:symbol], row[:held] ] }).to eq("NVDA" => true, "ASML" => false)
  end

  it "keeps to the screen's window" do
    create(:technical_observation, asset: watched, observed_at: (Trading::UseCases::LoadSignals::WINDOW_DAYS + 1).days.ago)

    expect(described_class.call(include_held: false, user: user).size).to eq(1)
  end
end
