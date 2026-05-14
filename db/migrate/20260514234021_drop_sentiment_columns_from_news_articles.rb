class DropSentimentColumnsFromNewsArticles < ActiveRecord::Migration[8.1]
  def up
    remove_column :news_articles, :sentiment
    remove_column :news_articles, :sentiment_score
    remove_column :news_articles, :sentiment_analyzed_at
  end

  def down
    add_column :news_articles, :sentiment, :string
    add_column :news_articles, :sentiment_score, :integer
    add_column :news_articles, :sentiment_analyzed_at, :datetime
  end
end
