require "rails_helper"

RSpec.describe SplitDetected do
  subject(:event) do
    described_class.new(asset_id: 1, stock_split_id: 5, ratio_from: 1, ratio_to: 4)
  end

  it "stores attributes" do
    expect(event.asset_id).to eq(1)
    expect(event.stock_split_id).to eq(5)
    expect(event.ratio_from).to eq(1)
    expect(event.ratio_to).to eq(4)
  end

  it "includes occurred_at from BaseEvent" do
    expect(event.occurred_at).to respond_to(:to_time)
  end
end
