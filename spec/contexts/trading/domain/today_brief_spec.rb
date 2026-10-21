require "rails_helper"

RSpec.describe Trading::Domain::TodayBrief do
  let(:asset) { build_stubbed(:asset) }

  def item(kind, days: nil, gap: nil)
    described_class::Item.new(kind: kind, asset: asset, days: days, date: nil, gap: gap)
  end

  def brief(candidates: [], tracks_anything: true, quotes_reliable: true)
    described_class.call(tracks_anything: tracks_anything, quotes_reliable: quotes_reliable, candidates: candidates)
  end

  it "is a first run when nothing is held or watched" do
    expect(brief(tracks_anything: false).state).to eq(:first_run)
  end

  it "is calm only when quotes are reliable and nothing qualifies" do
    expect(brief.state).to eq(:calm)
  end

  it "never says calm over quotes it cannot vouch for" do
    expect(brief(quotes_reliable: false).state).to eq(:stale)
  end

  it "keeps what does not depend on a price when quotes are stale, and drops the target distance" do
    result = brief(quotes_reliable: false, candidates: [ item(:maturity, days: 2), item(:target, gap: 1.0) ])

    expect(result.items.map(&:kind)).to eq([ :maturity ])
  end

  it "ranks maturities, then earnings, then targets, nearest first" do
    result = brief(candidates: [
      item(:target, gap: 1.0), item(:earnings, days: 5), item(:earnings, days: 2), item(:maturity, days: 9)
    ])

    expect(result.items.map { |i| [ i.kind, i.days || i.gap ] })
      .to eq([ [ :maturity, 9 ], [ :earnings, 2 ], [ :earnings, 5 ] ])
    expect(result.total).to eq(4)
  end

  it "puts a missed contribution before a share off its plan, and the widest gap first" do
    result = brief(candidates: [
      described_class::Item.new(kind: :allocation, subject: :crypto_share, gap: -8),
      described_class::Item.new(kind: :allocation, subject: :stocks_share, gap: 15),
      described_class::Item.new(kind: :contribution, target: 5_000)
    ])

    expect(result.items.map { |i| [ i.kind, i.subject ] })
      .to eq([ [ :contribution, nil ], [ :allocation, :stocks_share ], [ :allocation, :crypto_share ] ])
  end

  it "drops a share off its plan under stale quotes but keeps the contribution, which is not a price" do
    result = brief(quotes_reliable: false, candidates: [
      described_class::Item.new(kind: :allocation, subject: :stocks_share, gap: 15),
      described_class::Item.new(kind: :contribution, target: 5_000)
    ])

    expect(result.items.map(&:kind)).to eq([ :contribution ])
  end

  it "shows at most three items and reports how many qualified" do
    result = brief(candidates: Array.new(5) { |n| item(:earnings, days: n) })

    expect(result.items.size).to eq(3)
    expect(result.total).to eq(5)
  end
end
