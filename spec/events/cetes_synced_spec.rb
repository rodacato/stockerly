require "rails_helper"

RSpec.describe CetesSynced do
  it "stores count attribute" do
    event = described_class.new(count: 4)

    expect(event.count).to eq(4)
    expect(event.event_name).to eq("cetes_synced")
  end
end
