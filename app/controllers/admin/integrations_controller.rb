module Admin
  class IntegrationsController < BaseController
    rate_limit to: 5, within: 1.minute, only: :refresh_sync

    def create
      result = Admin::Integrations::ConnectProvider.call(
        admin: current_user,
        params: integration_params.to_h
      )

      if result.success?
        redirect_to admin_users_path, notice: "Provider connected successfully."
      else
        redirect_to admin_users_path, alert: result.failure.last
      end
    end

    def update
      result = Admin::Integrations::UpdateProvider.call(
        admin: current_user,
        params: update_params.to_h.merge(id: params[:id].to_i)
      )

      if result.success?
        redirect_to admin_users_path, notice: "Provider updated successfully."
      else
        redirect_to admin_users_path, alert: result.failure.last
      end
    end

    def destroy
      result = Admin::Integrations::DeleteProvider.call(
        admin: current_user,
        params: { id: params[:id].to_i }
      )

      if result.success?
        redirect_to admin_users_path, notice: "Provider deleted."
      else
        redirect_to admin_users_path, alert: result.failure.last
      end
    end

    def refresh_sync
      result = Admin::Integrations::RefreshSync.call(integration_id: params[:id])

      if result.success?
        redirect_back fallback_location: admin_assets_path, notice: "Integration sync enqueued."
      else
        redirect_back fallback_location: admin_assets_path, alert: result.failure.last
      end
    end

    private

    def integration_params
      params.require(:integration).permit(:provider_name, :provider_type, :api_key_encrypted)
    end

    def update_params
      params.require(:integration).permit(:api_key_encrypted, :daily_call_limit, :max_requests_per_minute)
    end
  end
end
