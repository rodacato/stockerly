require "rails_helper"

RSpec.describe Trading::Events::SplitDetected do
  subject(:event) do
    described_class.new(asset_id: 1, ex_date: Date.new(2026, 2, 15), ratio_from: 1, ratio_to: 4)
  end

  it "stores attributes" do
    expect(event.asset_id).to eq(1)
    expect(event.ex_date).to eq(Date.new(2026, 2, 15))
    expect(event.ratio_from).to eq(1)
    expect(event.ratio_to).to eq(4)
  end

  # The handler adjusts from the payload alone, so a row that moves or is
  # deleted between publish and consume cannot change what it applies.
  it "carries no key into the publisher's table" do
    expect(event.to_h).not_to include(:stock_split_id)
  end

  it "includes occurred_at from BaseEvent" do
    expect(event.occurred_at).to respond_to(:to_time)
  end
end
