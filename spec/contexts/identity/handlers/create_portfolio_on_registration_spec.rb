require "rails_helper"

RSpec.describe Identity::CreatePortfolioOnRegistration do
  let(:user) { create(:user) }

  it "creates a portfolio for the user" do
    event = Identity::UserRegistered.new(user_id: user.id, email: user.email)

    expect { described_class.call(event) }.to change(Portfolio, :count).by(1)
    expect(user.reload.portfolio).to be_present
    expect(user.portfolio.inception_date).to eq(Date.current)
  end

  it "does not create duplicate portfolio" do
    create(:portfolio, user: user)
    event = Identity::UserRegistered.new(user_id: user.id, email: user.email)

    expect { described_class.call(event) }.not_to change(Portfolio, :count)
  end
end
