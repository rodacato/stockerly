require "rails_helper"

RSpec.describe Identity::Handlers::InvalidateSessionsOnPasswordChange do
  let(:user) { create(:user) }

  it "destroys all remember tokens for the user" do
    create(:remember_token, user: user)
    create(:remember_token, user: user)
    event = Identity::Events::PasswordChanged.new(user_id: user.id)

    expect { described_class.call(event) }.to change { user.remember_tokens.count }.from(2).to(0)
  end

  it "does nothing when user has no remember tokens" do
    event = Identity::Events::PasswordChanged.new(user_id: user.id)

    expect { described_class.call(event) }.not_to raise_error
  end
end
