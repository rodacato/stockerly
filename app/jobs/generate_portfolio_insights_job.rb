class GeneratePortfolioInsightsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    users = User.joins(:portfolio).where(is_verified: true)

    users.find_each do |user|
      next unless user.portfolio.open_positions.exists?

      MarketData::UseCases::GeneratePortfolioInsight.call(user: user)
    end

    log_success("GeneratePortfolioInsights", "Generated insights for #{users.count} users")
  end
end
