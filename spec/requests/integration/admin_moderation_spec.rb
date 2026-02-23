require "rails_helper"

RSpec.describe "Admin moderation flow", type: :request do
  let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }
  let!(:regular_user) { create(:user, email: "user@example.com", password: "password123") }

  before do
    EventBus.subscribe(UserSuspended, CreateAuditLogOnSuspension)
    login_as(admin)
  end

  it "suspends a user and creates audit log" do
    patch suspend_admin_user_path(regular_user)
    expect(response).to redirect_to(admin_users_path)

    expect(regular_user.reload).to be_suspended
    expect(AuditLog.where(action: "user_suspended").count).to eq(1)
  end

  it "prevents suspending an admin" do
    another_admin = create(:user, :admin, email: "admin2@example.com")

    patch suspend_admin_user_path(another_admin)
    expect(response).to redirect_to(admin_users_path)
    expect(another_admin.reload).not_to be_suspended
  end
end
