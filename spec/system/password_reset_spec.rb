require "rails_helper"

RSpec.describe "Password reset flow", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "reset@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }

  it "navigates to forgot password page from login" do
    visit login_path
    click_link "Forgot password?"
    expect(page).to have_current_path(forgot_password_path)
    expect(page).to have_content("Forgot your password?")
  end

  it "submits email and sees success message" do
    visit forgot_password_path
    fill_in "Email", with: "reset@test.com"
    click_button "Send Reset Link"

    expect(page).to have_current_path(login_path)
    expect(page).to have_content("reset instructions")
  end

  it "visits reset link with valid token and shows form" do
    token = user.password_reset_token
    visit reset_password_path(token)

    expect(page).to have_content("Create new password")
  end

  it "resets password with valid new password" do
    token = user.password_reset_token
    visit reset_password_path(token)

    fill_in "New Password", with: "newpassword456"
    fill_in "Confirm Password", with: "newpassword456"
    click_button "Reset Password"

    expect(page).to have_current_path(login_path)
    expect(page).to have_content("Password reset successfully")
  end

  it "shows error for invalid token" do
    visit reset_password_path("invalid-token-abc")

    expect(page).to have_current_path(forgot_password_path)
    expect(page).to have_content("Invalid or expired")
  end
end
