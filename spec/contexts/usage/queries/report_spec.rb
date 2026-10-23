require "rails_helper"

RSpec.describe Usage::Queries::Report do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.zone.local(2026, 10, 22, 12) }

  def event(name, at:, **properties) = UsageEvent.create!(name: name, occurred_at: at, properties: properties.stringify_keys)

  around { |example| travel_to(now) { example.run } }

  it "counts each catalogued event per week, oldest first, zero where nothing happened" do
    event("news.opened", at: now)
    event("news.opened", at: now - 1.week)
    event("news.opened", at: now - 1.week)

    counts = described_class.call(now: now)[:events].find { |entry, _| entry.name == "news.opened" }.last

    expect(counts.last(2)).to eq([ 2, 1 ])
    expect(counts.size).to eq(described_class::WEEKS)
  end

  it "sets each offer against the actions that came from it, and only those" do
    event("rule_suggestion.shown", at: now)
    event("rule_suggestion.shown", at: now)
    event("rule.created", at: now, via: "rule_suggestion")
    event("rule.created", at: now, via: "direct")

    funnel = described_class.call(now: now)[:funnels].find { |entry| entry[:funnel].key == "rule_suggestion" }

    expect(funnel[:rows].last.drop(1)).to eq([ 2, 1 ])
  end

  it "states how long a trade takes to capture over the last month" do
    [ 10, 20, 30, 40, 100 ].each { |seconds| event("trade.created", at: now - 1.day, seconds: seconds) }
    event("trade.created", at: now - 40.days, seconds: 999)

    expect(described_class.call(now: now)[:capture]).to eq(count: 5, p50: 30, p95: 88)
  end

  it "says the switch is off" do
    expect(described_class.call(now: now)[:enabled]).to be(false)
  end
end
