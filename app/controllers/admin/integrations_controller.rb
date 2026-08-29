module Admin
  class IntegrationsController < BaseController
    rate_limit to: 5, within: 1.minute, only: :refresh_sync

    def index
      @sources = MarketData::Domain::SourceCatalogue.all
      @integrations = Integration.where(provider_name: @sources.map(&:provider)).index_by(&:provider_name)
    end

    def create
      result = Administration::UseCases::Integrations::ConnectProvider.call(
        admin: current_user,
        params: integration_params.to_h
      )

      if result.success?
        redirect_to admin_integrations_path, notice: t("admin.integrations.flash.conectada")
      else
        redirect_to admin_integrations_path, alert: result.failure.last
      end
    end

    def update
      result = Administration::UseCases::Integrations::UpdateProvider.call(
        admin: current_user,
        params: update_params.to_h.merge(id: params[:id].to_i)
      )

      if result.success?
        redirect_to admin_integrations_path, notice: t("admin.integrations.flash.actualizada")
      else
        redirect_to admin_integrations_path, alert: result.failure.last
      end
    end

    def destroy
      result = Administration::UseCases::Integrations::DeleteProvider.call(
        admin: current_user,
        params: { id: params[:id].to_i }
      )

      if result.success?
        redirect_to admin_integrations_path, notice: t("admin.integrations.flash.eliminada")
      else
        redirect_to admin_integrations_path, alert: result.failure.last
      end
    end

    def refresh_sync
      result = Administration::UseCases::Integrations::RefreshSync.call(integration_id: params[:id])

      if result.success?
        redirect_back fallback_location: admin_integrations_path, notice: t("admin.integrations.flash.sincronizacion_encolada")
      else
        redirect_back fallback_location: admin_integrations_path, alert: result.failure.last
      end
    end

    private

    def integration_params
      params.require(:integration).permit(:provider_name, :provider_type)
    end

    def update_params
      params.require(:integration).permit(:daily_call_limit, :max_requests_per_minute, :api_key_encrypted)
    end
  end
end
