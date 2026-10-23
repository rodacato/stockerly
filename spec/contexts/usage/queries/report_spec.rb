require "rails_helper"

RSpec.describe Usage::Queries::Report do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.zone.local(2026, 10, 22, 12) }

  def event(name, at:, **properties) = UsageEvent.create!(name: name, occurred_at: at, properties: properties.stringify_keys)

  def switch(on, at:)
    SiteConfig.set(Usage::SWITCH, on)
    SiteConfig.find_by!(key: Usage::SWITCH).update_column(:updated_at, at)
  end

  around { |example| travel_to(now) { example.run } }

  it "counts each catalogued event per week, newest first, zero where nothing happened" do
    event("news.opened", at: now)
    event("news.opened", at: now - 1.week)
    event("news.opened", at: now - 1.week)

    counts = described_class.call(now: now)[:events].find { |entry, _| entry.name == "news.opened" }.last

    expect(counts.first(2)).to eq([ 1, 2 ])
    expect(counts.size).to eq(described_class::WEEKS)
  end

  it "sets each offer against the actions that came from it, and only those" do
    event("rule_suggestion.shown", at: now)
    event("rule_suggestion.shown", at: now)
    event("rule.created", at: now, via: "rule_suggestion")
    event("rule.created", at: now, via: "direct")

    funnel = described_class.call(now: now)[:funnels].find { |entry| entry[:funnel].key == "rule_suggestion" }

    expect(funnel[:rows].first.drop(1)).to eq([ 2, 1 ])
  end

  it "states how long a trade takes to capture over the last month" do
    [ 10, 20, 30, 40, 100 ].each { |seconds| event("trade.created", at: now - 1.day, seconds: seconds) }
    event("trade.created", at: now - 40.days, seconds: 999)

    expect(described_class.call(now: now)[:capture]).to eq(count: 5, p50: 30, max: 100)
  end

  it "says the switch is off, and that nothing was measured" do
    report = described_class.call(now: now)

    expect(report[:enabled]).to be(false)
    expect(report[:measured]).to all(be(false))
  end

  it "measures the weeks from the one the switch was turned on in" do
    switch(true, at: now - 2.weeks)

    expect(described_class.call(now: now)[:measured]).to eq([ true, true, true, false, false, false, false, false ])
  end

  it "keeps the weeks before the switch went off as measured, once something was recorded" do
    event("news.opened", at: now - 2.weeks)
    switch(false, at: now - 1.week)

    expect(described_class.call(now: now)[:measured].first(3)).to eq([ false, true, true ])
  end
end
