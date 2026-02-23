module RequestHelpers
  def login_as(user, password: "password123")
    ensure_onboarded(user)
    post login_path, params: { email: user.email, password: password }
  end

  def ensure_onboarded(user)
    return if user.watchlist_items.exists?

    asset = Asset.first || FactoryBot.create(:asset)
    FactoryBot.create(:watchlist_item, user: user, asset: asset)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
