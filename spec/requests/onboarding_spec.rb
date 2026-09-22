require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let!(:user) { create(:user, :admin, onboarded_at: nil) }

  before { login_as_without_onboarding(user) }

  describe "GET /onboarding/integrations" do
    let!(:integration) { create(:integration, :keyless, provider_name: "Alpaca") }

    it "renders the integrations step" do
      get onboarding_integrations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Alpaca")
    end
  end

  # ON-06: the wall used to come out alphabetical, which put Banxico second and
  # level with five keys the wizard never checks.
  describe "the order the keys are asked for" do
    before do
      %w[Alpaca Banxico CoinGecko DataBursatil ExchangeRate Finnhub].each do |provider|
        create(:integration, :keyless, provider_name: provider)
      end

      get onboarding_integrations_path
    end

    it "asks for Banxico first, then by what skipping each key costs" do
      asked = response.body.scan(/id="api_key_(\d+)"/).flatten
                      .map { |id| Integration.find(id).provider_name }

      expect(asked).to eq(%w[Banxico CoinGecko DataBursatil Alpaca Finnhub ExchangeRate])
    end

    # An explicit order is a list a new provider can fall off, and the step is
    # the only place its key can be typed. Falling off ranks it last; it must
    # not drop the record out of the wall.
    it "still shows a provider nobody put in the order" do
      create(:integration, :keyless, provider_name: "Nueva Fuente")

      get onboarding_integrations_path

      expect(response.body).to include("Nueva Fuente")
    end
  end

  describe "PATCH /onboarding/integrations" do
    let!(:integration) { create(:integration, :keyless, provider_name: "Alpaca") }

    it "saves API keys and moves to the assets step" do
      patch onboarding_save_integrations_path, params: {
        api_keys: { integration.id.to_s => "my_api_key" }
      }

      expect(response).to redirect_to(onboarding_assets_path)
      expect(integration.reload.api_key_encrypted).to eq("my_api_key")
    end

    # Banxico is the one key this step can exercise on the spot, and its failure
    # used to be flashed over step 2, where the only control is Atrás.
    it "reports a Banxico that did not answer on the step that asked for the key" do
      banxico = create(:integration, :keyless, provider_name: "Banxico")
      stub_request(:get, %r{banxico\.org\.mx/SieAPIRest/service/v1/series/SF60653/datos/})
        .to_return(status: 500, body: "boom")

      patch onboarding_save_integrations_path, params: {
        api_keys: { banxico.id.to_s => "banxico_token" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("onboarding.integraciones.tc_error"))
      expect(response.body).to include(I18n.t("onboarding.integrations.titulo"))
      expect(banxico.reload.api_key_encrypted).to eq("banxico_token")
    end
  end

  describe "GET /onboarding/assets" do
    it "renders the assets step" do
      get onboarding_assets_path
      expect(response).to have_http_status(:ok)
    end

    # Skipping the assets must not skip the security step behind them (D52).
    it "skips to the security step, not past it" do
      get onboarding_assets_path

      expect(response.body).to include(%(href="#{onboarding_security_path}"))
      expect(response.body).not_to include(%(href="#{onboarding_complete_path}"))
    end
  end

  describe "POST /onboarding/assets" do
    # D52 put Seguridad between the assets and the summary, so the wizard is
    # four steps and this one no longer lands on the last.
    it "creates the chosen assets and moves to the security step" do
      expect {
        post onboarding_save_assets_path, params: { symbols: %w[AAPL BTC] }
      }.to change(Asset, :count).by(2)

      expect(response).to redirect_to(onboarding_security_path)
    end
  end

  describe "GET /onboarding/complete" do
    it "renders the summary" do
      get onboarding_complete_path
      expect(response).to have_http_status(:ok)
    end

    # Cards one and two put a measured figure in the number slot. The third put
    # the word "Listo" there, for a sync that only starts on the next click.
    it "summarises only the figures it has measured" do
      register_queue_worker

      get onboarding_complete_path

      expect(response.body.scan("font-mono text-xl font-bold").size).to eq(2)
      expect(response.body).not_to include("bg-warning-bg")
    end

    # ON-08: on a self-hosted install the worker is a separate process, so the
    # last click of the wizard can promise a sync that nothing will pick up.
    it "warns when no worker is attending the queue" do
      get onboarding_complete_path

      expect(response.body).to include(I18n.t("onboarding.complete.sin_worker_titulo"))
      expect(response.body).to include("bin/jobs")
    end

    it "says nothing about the queue when a worker is attending it" do
      register_queue_worker

      get onboarding_complete_path

      expect(response.body).not_to include(I18n.t("onboarding.complete.sin_worker_titulo"))
    end

    # The warning informs, it does not gate: a reader about to start bin/jobs
    # in the next terminal must still be able to finish the wizard.
    it "still offers both ways out when no worker is attending" do
      get onboarding_complete_path

      expect(response.body).to include(I18n.t("onboarding.complete.lanzar"))
      expect(response.body).to include(I18n.t("onboarding.complete.sin_sincronizar"))
    end

    it "is the last of the four steps" do
      get onboarding_complete_path

      expect(response.body).to include("Paso 4 de 4")
    end

    it "leads back to the step before it, which is security" do
      get onboarding_complete_path

      expect(response.body).to include(%(href="#{onboarding_security_path}"))
    end

    # A keyless source cannot take a key, so counting it promises a total the
    # reader can never reach.
    it "counts only the sources that take a key" do
      create(:integration, provider_name: "Alpaca")
      create(:integration, :keyless, provider_name: "Finnhub")
      create(:integration, :keyless, provider_name: "Yahoo Finance")

      get onboarding_complete_path

      expect(response.body).to include("1/2")
    end
  end

  describe "POST /onboarding/launch" do
    # D30: the wizard hands over to Welcome, which is the step that marks the
    # user onboarded. Stamping it here would make Welcome unreachable, because
    # WelcomeController sends an onboarded user to the dashboard.
    it "hands over to Welcome without marking the user onboarded" do
      post onboarding_launch_path

      expect(response).to redirect_to(welcome_path)
      expect(user.reload.onboarded?).to be false
    end

    it "launches the initial sync by default" do
      create(:asset, asset_type: :stock)

      expect { post onboarding_launch_path }.to have_enqueued_job(SyncPriorityAssetsJob)
    end

    it "skips the sync when asked to" do
      create(:asset, asset_type: :stock)

      expect {
        post onboarding_launch_path, params: { launch_sync: "false" }
      }.not_to have_enqueued_job(SyncPriorityAssetsJob)
    end
  end

  describe "the whole flow, end to end" do
    it "ends at Welcome, and Welcome is what marks the user onboarded" do
      post onboarding_launch_path
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hola")

      post complete_welcome_path

      expect(response).to redirect_to(dashboard_path)
      expect(user.reload.onboarded?).to be true
    end
  end

  # D149: the bar reports work finished, not the ordinal of the screen being
  # looked at, so it starts empty and only the hand-off fills it.
  describe "the progress bar" do
    it "opens the first step at zero" do
      get onboarding_integrations_path

      expect(response.body).to include("width: 0%")
      expect(response.body).to include(">0%<")
    end

    it "leaves a quarter on the last step, which still has an action on it" do
      get onboarding_complete_path

      expect(response.body).to include("width: 75%")
      expect(response.body).not_to include("width: 100%")
    end
  end

  describe "guard: already onboarded" do
    before { user.update!(onboarded_at: Time.current) }

    # The negative criterion on the slice card: nothing in the flow stays
    # reachable once onboarded_at is set.
    it "sends every step to the dashboard" do
      [ onboarding_integrations_path, onboarding_assets_path, onboarding_complete_path ].each do |path|
        get path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
