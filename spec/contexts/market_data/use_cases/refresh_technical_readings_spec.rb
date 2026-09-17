require "rails_helper"

# D126: during the session the reading refreshes and the events wait for the close.
RSpec.describe MarketData::UseCases::RefreshTechnicalReadings do
  def seed_history(asset, closes)
    closes.each_with_index do |close, i|
      create(:asset_price_history, asset: asset, date: (closes.size - 1 - i).days.ago.to_date, close: close)
    end
  end

  it "rewrites the reading from today's close, the price of the moment (#483)" do
    asset = create(:asset, symbol: "AAPL", current_price: 120)
    seed_history(asset, Array.new(59, 100.0) + [ 120.0 ])

    described_class.call

    expect(asset.reload.technical_reading.readings["close"]).to eq(120.0)
  end

  # Negative: a crossing that only today's unfinished bar shows is not an event.
  it "persists no observation, even when today's bar crosses a threshold" do
    asset = create(:asset, symbol: "AAPL", current_price: 10)
    seed_history(asset, Array.new(15, 100.0) + [ 10.0 ])

    expect { described_class.call }.not_to change(TechnicalObservation, :count)
    expect(asset.reload.technical_reading).to be_present
  end

  it "leaves fixed income out" do
    bond = create(:asset, :fixed_income, symbol: "CETES28", current_price: 10)
    seed_history(bond, Array.new(20, 10.0))

    described_class.call

    expect(bond.reload.technical_reading).to be_nil
  end
end
