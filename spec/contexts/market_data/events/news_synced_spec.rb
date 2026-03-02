require "rails_helper"

RSpec.describe MarketData::NewsSynced do
  subject(:event) { described_class.new(count: 5) }

  it "stores count" do
    expect(event.count).to eq(5)
  end

  it "includes occurred_at from BaseEvent" do
    expect(event.occurred_at).to respond_to(:to_time)
  end
end
