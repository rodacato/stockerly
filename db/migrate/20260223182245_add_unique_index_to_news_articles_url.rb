class AddUniqueIndexToNewsArticlesUrl < ActiveRecord::Migration[8.1]
  def change
    add_index :news_articles, :url, unique: true
  end
end
