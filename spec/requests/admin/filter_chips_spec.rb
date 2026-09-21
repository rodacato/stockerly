require "rails_helper"

# Registros and Errores each carried a byte-identical copy of the same chip
# row, and neither announced itself as a group or said which chip was picked.
RSpec.describe "Admin filter chips", type: :request do
  let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }

  before { login_as(admin) }

  def group(label)
    response.parsed_body.at_css(%([role="tablist"][aria-label="#{label}"]))
  end

  def selected(label)
    group(label).css(%([role="tab"][aria-selected="true"])).map { |tab| tab.text.strip }
  end

  it "reads the severity row as one group with one pick" do
    get admin_logs_path(severity: "error")

    expect(selected(I18n.t("admin.logs.index.severidad")))
      .to eq([ I18n.t("admin.logs.index.severidades.error") ])
  end

  it "falls back to the chip that filters nothing" do
    get admin_logs_path

    expect(selected(I18n.t("admin.logs.index.severidad"))).to eq([ I18n.t("admin.logs.index.todos") ])
  end

  it "reads the origin row the same way, from the same component" do
    SiteConfig.set("developer_mode", true)

    get admin_errors_path(source: "job")

    expect(selected(I18n.t("admin.errors.index.origen")))
      .to eq([ I18n.t("admin.errors.index.origenes.job") ])
  end
end
