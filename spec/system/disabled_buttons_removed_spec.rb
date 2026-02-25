require "rails_helper"

RSpec.describe "Disabled button placeholders removed", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "buttons@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }

  before do
    visit login_path
    fill_in "Email", with: "buttons@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "news page does not show disabled Subscribe Now button" do
    visit news_path
    expect(page).not_to have_button("Subscribe Now")
  end

  it "profile page does not show disabled Share Profile button" do
    visit profile_path
    expect(page).not_to have_button("Share Profile")
  end

  it "profile settings does not show disabled Privacy Mode toggle" do
    visit profile_path
    expect(page).not_to have_content("Privacy Mode")
  end
end
