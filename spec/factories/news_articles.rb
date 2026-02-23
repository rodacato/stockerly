FactoryBot.define do
  factory :news_article do
    sequence(:title) { |n| "Breaking News #{n}" }
    source { "Bloomberg" }
    published_at { 1.hour.ago }
    summary { "Article summary text" }
    related_ticker { "AAPL" }
    sequence(:url) { |n| "https://example.com/news-#{n}" }
  end
end
