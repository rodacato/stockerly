module Admin
  class PoolKeysController < BaseController
    def create
      result = Administration::Integrations::AddPoolKey.call(
        admin: current_user,
        params: pool_key_params.to_h.merge(integration_id: params[:integration_id].to_i)
      )

      if result.success?
        redirect_to admin_integrations_path, notice: "API key added to pool."
      else
        redirect_to admin_integrations_path, alert: result.failure.last
      end
    end

    def toggle
      result = Administration::Integrations::TogglePoolKey.call(
        admin: current_user,
        params: { id: params[:id].to_i }
      )

      if result.success?
        status = result.value!.enabled ? "enabled" : "disabled"
        redirect_to admin_integrations_path, notice: "API key #{status}."
      else
        redirect_to admin_integrations_path, alert: result.failure.last
      end
    end

    def destroy
      result = Administration::Integrations::RemovePoolKey.call(
        admin: current_user,
        params: { id: params[:id].to_i }
      )

      if result.success?
        redirect_to admin_integrations_path, notice: "API key removed from pool."
      else
        redirect_to admin_integrations_path, alert: result.failure.last
      end
    end

    private

    def pool_key_params
      params.require(:api_key_pool).permit(:name, :api_key_encrypted)
    end
  end
end
