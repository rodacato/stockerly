require "rails_helper"

RSpec.describe MarketData::Contracts::SentimentResponseContract do
  subject(:contract) { described_class.new }

  it "passes with valid article sentiments" do
    result = contract.call(articles: [
      { title: "Stock rises", sentiment: "bullish", score: 80 },
      { title: "Market dips", sentiment: "bearish", score: 30 }
    ])
    expect(result).to be_success
  end

  it "fails with invalid sentiment value" do
    result = contract.call(articles: [
      { title: "News", sentiment: "positive", score: 50 }
    ])
    expect(result).to be_failure
  end
end
