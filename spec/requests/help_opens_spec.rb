require "rails_helper"

RSpec.describe "Help opens", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current) }

  it "counts a known figure under help:<figure>" do
    login_as(user)

    2.times { post help_opens_path("veredicto") }

    expect(response).to have_http_status(:no_content)
    expect(AppOpen.total(prefix: "help:")).to eq(2)
    expect(AppOpen.where(path: "help:veredicto").sum(:count)).to eq(2)
  end

  it "refuses a figure it does not know, so the counter cannot be filled with anything" do
    login_as(user)

    post help_opens_path("whatever")

    expect(response).to have_http_status(:unprocessable_content)
    expect(AppOpen.count).to eq(0)
  end

  it "counts nothing for a logged-out visitor" do
    post help_opens_path("veredicto")

    expect(response).to redirect_to(login_path)
    expect(AppOpen.count).to eq(0)
  end
end
