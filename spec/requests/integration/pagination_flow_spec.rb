require "rails_helper"

RSpec.describe "Pagination flow", type: :request do
  let!(:user) { create(:user, email: "pager@example.com", password: "password123") }

  before do
    login_as(user)
  end

  it "paginates admin logs" do
    delete logout_path
    admin = create(:user, :admin, email: "admin_pag@example.com", password: "password123")
    login_as(admin)

    create_list(:system_log, 25)

    get admin_logs_path
    expect(response).to have_http_status(:ok)

    get admin_logs_path(page: 2)
    expect(response).to have_http_status(:ok)
  end
end
