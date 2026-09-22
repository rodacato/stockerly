require "rails_helper"

RSpec.describe "Reglas", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current) }

  before { login_as(user) }

  # D143: the preference switches are configuration set once, so they live on
  # the hub that owns configuration. Reglas keeps a line and a door.
  describe "where notification preferences live" do
    it "does not render the switches on the screen that only reads outcomes" do
      get alerts_path

      expect(response.body).not_to include(%(data-toggle-url-value="#{update_preferences_path}"))
      expect(response.body).not_to include(I18n.t("settings.show.digest"))
    end

    it "points at Ajustes instead" do
      get alerts_path

      expect(response.body).to include(I18n.t("alerts.index.avisos_nota"))
      expect(response.body).to include(%(href="#{settings_path}"))
    end

    # Negative: the hub is where the panel belongs, so it has to still be there.
    it "keeps the panel on the hub that owns it" do
      get settings_path

      expect(response.body).to include(%(data-toggle-url-value="#{update_preferences_path}"))
      expect(response.body).to include(I18n.t("settings.show.digest"))
    end
  end

  describe "the heading ranks" do
    it "gives Tus reglas the only primary rank on the screen" do
      get alerts_path

      expect(response.body).to match(
        %r{<h2 class="font-display text-2xl font-bold text-fg-default">\s*#{I18n.t('alerts.index.tus_reglas')}\s*</h2>}
      )
      expect(response.body.scan(/font-display text-2xl font-bold/).size).to eq(1)
    end
  end
end
