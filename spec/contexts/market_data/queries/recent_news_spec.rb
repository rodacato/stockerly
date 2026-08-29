require "rails_helper"

RSpec.describe MarketData::Queries::RecentNews do
  let(:asset) { create(:asset, symbol: "AAPL") }

  it "returns the asset's articles, newest first" do
    older = create(:news_article, related_ticker: "AAPL", published_at: 3.days.ago)
    newer = create(:news_article, related_ticker: "AAPL", published_at: 1.hour.ago)
    create(:news_article, related_ticker: "MSFT", published_at: 1.hour.ago)

    expect(described_class.call(asset: asset).to_a).to eq([ newer, older ])
  end

  it "returns nothing when the asset has no articles" do
    create(:news_article, related_ticker: "MSFT", published_at: 1.hour.ago)

    expect(described_class.call(asset: asset)).to be_empty
  end

  it "matches articles filed under a symbol the asset used to carry" do
    asset.update!(symbol: "META", former_symbols: [ "FB" ])
    article = create(:news_article, related_ticker: "FB", published_at: 2.days.ago)

    expect(described_class.call(asset: asset).to_a).to eq([ article ])
  end

  it "excludes an article published before the window rather than showing it as old" do
    create(:news_article, related_ticker: "AAPL", published_at: (described_class::WINDOW_DAYS + 1).days.ago)

    expect(described_class.call(asset: asset)).to be_empty
  end

  it "caps how many articles it returns" do
    (described_class::LIMIT + 2).times { |n| create(:news_article, related_ticker: "AAPL", published_at: n.hours.ago) }

    expect(described_class.call(asset: asset).size).to eq(described_class::LIMIT)
  end
end
