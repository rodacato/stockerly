module Identity
  class InvalidateSessionsOnPasswordChange
    def self.call(event)
      user_id = event.is_a?(Hash) ? event[:user_id] : event.user_id
      user = User.find(user_id)
      user.remember_tokens.destroy_all
    end
  end
end
