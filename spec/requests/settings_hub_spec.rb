require "rails_helper"

RSpec.describe "Ajustes", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current, full_name: "Adrian Castillo") }

  before { login_as(user) }

  it "gathers the sections that used to be split between profile and admin" do
    get settings_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("settings.show.cuenta"))
    expect(response.body).to include(I18n.t("settings.show.avisos_titulo"))
    expect(response.body).to include(I18n.t("settings.show.instancia_titulo"))
    expect(response.body).to include(I18n.t("settings.show.datos_titulo"))
  end

  # The tile earns its place by carrying a distinct glyph per destination, and
  # receipt_long carried two: Historial on Activos and Registros here.
  describe "the nav row's icon tile" do
    def nav_rows(path)
      get path
      response.parsed_body.css("a").filter_map do |link|
        icon = link.at_css("span.size-10 svg[data-icon]")
        [ icon["data-icon"], link["href"] ] if icon
      end
    end

    it "never sends one glyph to two destinations" do
      rows = (nav_rows(settings_path) + nav_rows(assets_path)).uniq
      repeated = rows.map(&:first).tally.select { |_, count| count > 1 }

      expect(repeated).to be_empty
    end

    it "leaves the receipt to Historial, which is the one made of receipts" do
      expect(nav_rows(assets_path)).to include([ "receipt_long", positions_path ])
      expect(nav_rows(settings_path).map(&:first)).not_to include("receipt_long")
    end
  end

  # D5: on a single-user instance the admin split was a costume. The surfaces
  # stay where they are; what changes is that they are reachable from here.
  it "links to the instance surfaces instead of reimplementing them" do
    get settings_path

    expect(response.body).to include(%(href="#{admin_integrations_path}"))
    expect(response.body).to include(%(href="#{admin_logs_path}"))
    expect(response.body).to include(%(href="#{admin_settings_path}"))
    expect(response.body).to include(%(href="/admin/jobs"))
  end

  # D147: /admin/jobs mounts Mission Control under its own layout, with none
  # of Stockerly's chrome and no route back into its navigation. It is the one
  # row in the product that strands you, and it used to signal least.
  describe "the row that leaves Stockerly" do
    def jobs_row
      get settings_path
      response.parsed_body.at_css(%(a[href="/admin/jobs"]))
    end

    it "marks it with the glyph the product already uses for leaving" do
      glyphs = jobs_row.css("svg[data-icon]").pluck("data-icon")

      expect(glyphs).to include("open_in_new")
      expect(glyphs).not_to include("chevron_right")
    end

    it "actually opens a new tab, so the mark is literally true" do
      row = jobs_row

      expect(row["target"]).to eq("_blank")
      expect(row["rel"]).to include("noopener")
    end

    it "says it in the accessible name too" do
      expect(jobs_row.text).to include(I18n.t("comun.abre_pestana"))
    end

    # Negative: one rank plus one boolean. Every other row keeps the chevron
    # and stays inside the product.
    it "leaves every other row unmarked" do
      get settings_path
      others = response.parsed_body.css("a").select { |a| a.at_css("span.size-10 svg[data-icon]") }
                       .reject { |a| a["href"] == "/admin/jobs" }

      expect(others).not_to be_empty
      expect(others.filter_map { |a| a["target"] }).to be_empty
      expect(others.flat_map { |a| a.css("svg[data-icon]").pluck("data-icon") }).not_to include("open_in_new")
    end
  end

  # ADR-020: the errors row is the developer surface, not a permanent part of
  # the hub.
  it "hides the errors row while developer mode is off" do
    get settings_path

    expect(response.body).not_to include(%(href="#{admin_errors_path}"))
  end

  it "shows the errors row once developer mode is on" do
    SiteConfig.set("developer_mode", true)

    get settings_path

    expect(response.body).to include(%(href="#{admin_errors_path}"))
  end

  it "offers both email switches, wired to the endpoint that persists them" do
    get settings_path

    expect(response.body).to include(I18n.t("settings.show.digest"))
    expect(response.body).to include(I18n.t("settings.show.urgente"))
    expect(response.body).to include(update_preferences_path)
  end

  # D16 left the in-app inbox always on, and a switch that does nothing is the
  # defect this slice's precondition existed to remove.
  it "does not offer a switch for the bell, which cannot be turned off" do
    get settings_path

    expect(response.body).to include(I18n.t("settings.show.avisos_campana"))
    # Two channels deliver, so two switches exist. Asserting the absence of
    # "browser_push" stopped meaning anything once the column was dropped —
    # a name for nothing cannot fail.
    expect(response.body.scan(/data-toggle-field-value=/).size).to eq(2)
  end

  it "shows the currency control on the user's current choice" do
    get settings_path

    expect(response.body).to include("MXN")
    expect(response.body).to include(update_currency_path)
  end

  # Rescued from the profile tab this hub replaced: the zone is fixed for the
  # whole instance, so the screen states it instead of offering a control.
  it "states the timezone every date is rendered in" do
    get settings_path

    expect(response.body).to include(I18n.t("settings.show.zona_horaria"))
    expect(response.body).to include(I18n.t("settings.show.zona_horaria_valor"))
  end

  # AJ-04: the zone wore the chrome of an unselected option in the two pill
  # groups above it, so the one value in the card you cannot change read as the
  # most pressable thing in it. The chrome's absence is the assertion.
  it "renders the timezone as a value, not as an option to press" do
    get settings_path

    zone = Capybara.string(response.body).find("span", text: I18n.t("settings.show.zona_horaria_valor"))

    expect(zone[:class]).not_to include("bg-bg-muted")
    expect(zone[:class]).not_to include("font-semibold")
  end

  # D58: the two pills on this screen looked identical and committed
  # differently — theme applied on click, currency waited for a button nothing
  # drew. A choice you can make and forget to submit is the failure this
  # removes, so the button's absence is the assertion.
  it "commits the currency on select, with no Guardar to forget" do
    get settings_path

    expect(response.body).to include('data-controller="choice"')
    expect(response.body).to include('data-choice-param-value="profile[preferred_currency]"')
    expect(response.body).to include('data-choice-value="MXN"')
    expect(response.body).to include('data-choice-value="USD"')
    expect(response.body).not_to include('type="submit" value="Guardar"')
  end

  # Tus datos is where a person goes looking for how to get data in, not only
  # for how to get it out.
  it "opens the importer from the data section" do
    get settings_path

    expect(response.body).to include(%(href="#{new_trade_import_path}"))
    expect(response.body).to include(I18n.t("settings.show.importar"))
  end

  # The importer reads Stockerly's own columns (Trading::Domain::CsvRows), so a
  # broker's export fails; the row used to promise exactly that.
  it "describes the importer by the format it actually reads" do
    get settings_path

    expect(response.body).to include("formato de Stockerly")
    expect(response.body).not_to include("CSV de tu broker")
  end

  it "offers both deletions, and says which one keeps the account" do
    get settings_path

    expect(response.body).to include(I18n.t("settings.show.borrar_trading_desc"))
    expect(response.body).to include(I18n.t("settings.show.borrar_cuenta_desc"))
  end

  describe "the nav" do
    it "points Ajustes here" do
      get settings_path

      expect(response.body).to include(%(href="#{settings_path}"))
    end

    it "keeps the tab lit on the account screens it links to" do
      [ edit_account_settings_path, edit_password_settings_path ].each do |path|
        get path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(href="#{settings_path}"))
      end
    end
  end

  describe "borrar datos" do
    let(:portfolio) { create(:portfolio, user: user, inception_date: Date.new(2025, 11, 11)) }
    let(:asset) { create(:asset, :stock, symbol: "VT") }

    def stock_the_portfolio
      position = create(:position, portfolio: portfolio, asset: asset)
      create(:trade, portfolio: portfolio, asset: asset, position: position)
      create(:portfolio_snapshot, portfolio: portfolio)
    end

    it "shows what borrar movimientos would remove" do
      stock_the_portfolio

      get settings_path

      expect(response.body).to include(I18n.t("settings.show.borrar_trading"))
      expect(response.body).to include(I18n.t("settings.show.borrar_cuenta"))
    end

    it "removes the movements and leaves the account standing" do
      stock_the_portfolio

      delete trading_data_settings_path

      expect(response).to redirect_to(settings_path)
      expect(portfolio.trades.count).to eq(0)
      expect(portfolio.positions.count).to eq(0)
      expect(portfolio.snapshots.count).to eq(0)
      expect(portfolio.reload.inception_date).to be_nil
      expect(User.exists?(user.id)).to be(true)
      expect(Asset.where(symbol: "VT")).to exist
    end

    # Offering a button that deletes nothing invites the click that teaches you
    # it deletes nothing.
    it "disables the movements button when there is nothing to remove" do
      portfolio

      get settings_path

      expect(response.body).to include("disabled")
    end

    it "deletes the account and sends the instance back to the wizard" do
      stock_the_portfolio

      delete account_settings_path

      expect(response).to redirect_to(setup_path)
      expect(User.exists?(user.id)).to be(false)
      expect(Portfolio.where(user_id: user.id)).not_to exist
      expect(Trade.count).to eq(0)
    end

    # The expensive half of the database: none of it is personal, and refetching
    # it costs provider calls.
    it "keeps the catalogue, the rate history and the integrations on either path" do
      stock_the_portfolio
      FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2025, 11, 11), rate: 20.1, source: "banxico")

      delete account_settings_path

      expect(Asset.where(symbol: "VT")).to exist
      expect(FxRateHistory.count).to eq(1)
    end
  end
end
