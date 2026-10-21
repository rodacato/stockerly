require "rails_helper"

RSpec.describe "Volatility on the dashboard", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }

  before { login_as(user) }

  it "shows the VIX under its own name, with its level, date and the IPC caveat" do
    create(:market_index, symbol: "VIX", name: "VIX", value: 17.43)

    get dashboard_path

    expect(response.body).to include(I18n.t("dashboard.show.volatilidad"))
    expect(response.body).to include("17.4")
    expect(response.body).to include("Normal")
    expect(response.body).to include("no dice nada del IPC")
    expect(response.body).not_to include("FEAR &amp; GREED · ACCIONES")
  end

  it "explains itself with a ? and counts it as a known figure" do
    create(:market_index, symbol: "VIX", name: "VIX", value: 17.43)

    get dashboard_path
    expect(response.body).to include(ERB::Util.html_escape(I18n.t("dashboard.ayuda.volatilidad.cuerpo")))

    post help_opens_path("volatilidad")
    expect(response).to have_http_status(:no_content)
  end

  it "shows nothing for a reading that is too old" do
    create(:market_index, symbol: "VIX", name: "VIX", value: 17.43).update_columns(updated_at: 6.days.ago)

    get dashboard_path

    expect(response.body).not_to include(I18n.t("dashboard.show.volatilidad"))
  end
end
