class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :news_articles, [ :related_ticker, :published_at ],
              name: "index_news_articles_on_ticker_and_published",
              algorithm: :concurrently,
              if_not_exists: true
    add_index :trades, [ :portfolio_id, :executed_at ],
              name: "index_trades_on_portfolio_and_executed",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
