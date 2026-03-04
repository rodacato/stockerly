class AddSentimentToNewsArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :news_articles, :sentiment, :string
    add_column :news_articles, :sentiment_score, :integer
    add_column :news_articles, :sentiment_analyzed_at, :datetime
  end
end
