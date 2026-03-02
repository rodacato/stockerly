require "rails_helper"

RSpec.describe Trading::TradeDeleted do
  it "creates event with all attributes" do
    event = described_class.new(
      trade_id: 1,
      user_id: 2,
      position_id: 3
    )

    expect(event.trade_id).to eq(1)
    expect(event.user_id).to eq(2)
    expect(event.position_id).to eq(3)
    expect(event.occurred_at).to be_present
  end
end
