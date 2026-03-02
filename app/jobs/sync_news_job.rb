# Fetches latest news articles from Polygon.io and upserts into the database.
class SyncNewsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    result = MarketData::SyncArticles.call

    if result.success?
      log_sync_success("News Sync", message: "#{result.value!} new articles")
    else
      log_sync_failure("News Sync", result.failure[1])
    end
  end
end
