require "rails_helper"

# Registros and Errores each carried a nine-line dashed card of their own — a
# second empty state outside the kit, and then a third.
RSpec.describe "Admin empty states", type: :request do
  let!(:admin) { create(:user, :admin, email: "adminempty@example.com", password: "password123") }

  before { login_as(admin) }

  def empty_state
    response.parsed_body.at_css(".border-dashed")
  end

  it "says the log is empty in the kit's empty state" do
    get admin_logs_path

    expect(empty_state.text).to include(I18n.t("admin.logs.index.vacio"))
    expect(empty_state["class"]).to include("py-16")
  end

  it "offers the way out of a filter that matched nothing" do
    get admin_logs_path(search: "nada de nada")

    expect(empty_state.text).to include(I18n.t("admin.logs.index.sin_coincidencias"))
    expect(empty_state.at_css("a")["href"]).to eq(admin_logs_path)
  end

  it "says the error log is empty in the same one" do
    SiteConfig.set("developer_mode", true)

    get admin_errors_path

    expect(empty_state.text).to include(I18n.t("admin.errors.index.vacio"))
    expect(empty_state["class"]).to include("py-16")
  end

  it "offers no way out when no filter is what emptied it" do
    get admin_logs_path

    expect(empty_state.at_css("a")).to be_nil
  end
end
