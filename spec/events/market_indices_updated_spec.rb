require "rails_helper"

RSpec.describe MarketIndicesUpdated do
  subject(:event) { described_class.new(count: 4) }

  it "stores count" do
    expect(event.count).to eq(4)
  end

  it "includes occurred_at from BaseEvent" do
    expect(event.occurred_at).to respond_to(:to_time)
  end
end
