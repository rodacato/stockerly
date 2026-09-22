require "rails_helper"

# AU-06: the auth card is one centred column at every width. The desktop-only
# brand panel it replaced was the product's single surface that did not reflow,
# and the wordmark it carried already rides the card at every size through
# `shared/_auth_header`.
RSpec.describe "The auth layout", type: :request do
  let!(:user) { create(:user, email: "shell@test.com", password: "password123", onboarded_at: Time.current) }

  it "centres one column instead of splitting the card on desktop" do
    get login_path

    expect(response.body).not_to include("lg:grid-cols-2")
    expect(Capybara.string(response.body)).to have_no_css("aside.bg-primary")
  end

  # The panel was the last renderer of this key inside the auth zone; only
  # `layouts/maintenance` prints it now.
  it "stops printing the open-source tagline beside the form" do
    get login_path

    expect(response.body).not_to include(I18n.t("auth.open_source"))
  end
end
