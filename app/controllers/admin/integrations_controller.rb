module Admin
  class IntegrationsController < BaseController
    rate_limit to: 5, within: 1.minute, only: :refresh_sync

    def refresh_sync
      result = Admin::Integrations::RefreshSync.call(integration_id: params[:id])

      if result.success?
        redirect_back fallback_location: admin_assets_path, notice: "Integration sync enqueued."
      else
        redirect_back fallback_location: admin_assets_path, alert: result.failure.last
      end
    end
  end
end
