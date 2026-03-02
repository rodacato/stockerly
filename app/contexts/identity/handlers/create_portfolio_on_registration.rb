module Identity
  class CreatePortfolioOnRegistration
    def self.call(event)
      user_id = event.is_a?(Hash) ? event[:user_id] : event.user_id
      user = User.find(user_id)
      return if user.portfolio.present?

      user.create_portfolio!(inception_date: Date.current, buying_power: 0)
    end
  end
end
