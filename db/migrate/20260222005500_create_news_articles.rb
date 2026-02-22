class CreateNewsArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :news_articles do |t|
      t.string   :title,          null: false
      t.text     :summary
      t.string   :image_url
      t.string   :source,         null: false
      t.string   :related_ticker
      t.string   :url
      t.datetime :published_at,   null: false

      t.timestamps
    end

    add_index :news_articles, :published_at
    add_index :news_articles, :related_ticker
  end
end
