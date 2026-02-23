module Admin
  class AssetsController < BaseController
    rate_limit to: 5, within: 1.minute, only: :trigger_sync
    rate_limit to: 10, within: 1.minute, only: :create

    def index
      result = Admin::Assets::ListAssets.call(params: filter_params)
      data = result.value!

      @pagy          = data[:pagy]
      @assets        = data[:assets]
      @total_count   = data[:total_count]
      @syncing_count = data[:syncing_count]
    end

    def trigger_sync
      result = Admin::Assets::TriggerSync.call(asset_id: params[:id])

      if result.success?
        redirect_to admin_assets_path, notice: "Sync job enqueued."
      else
        redirect_to admin_assets_path, alert: result.failure.last
      end
    end

    def trigger_sync_all
      result = Admin::Assets::TriggerSync.call(asset_type: params[:type])

      if result.success?
        redirect_to admin_assets_path, notice: "Bulk sync enqueued."
      else
        redirect_to admin_assets_path, alert: "Failed to enqueue sync."
      end
    end

    def create
      result = Admin::Assets::CreateAsset.call(admin: current_user, params: asset_params.to_h)

      if result.success?
        redirect_to admin_assets_path, notice: "Asset \"#{result.value!.symbol}\" created successfully."
      else
        redirect_to admin_assets_path, alert: result.failure.last.is_a?(Hash) ? result.failure.last.values.flatten.first : result.failure.last
      end
    end

    def toggle_status
      result = Admin::Assets::ToggleStatus.call(asset_id: params[:id])

      if result.success?
        redirect_to admin_assets_path, notice: "Asset status updated."
      else
        redirect_to admin_assets_path, alert: result.failure.last
      end
    end

    private

    def filter_params
      params.permit(:type, :search, :page).to_h.symbolize_keys
    end

    def asset_params
      params.require(:asset).permit(:symbol, :name, :asset_type, :country, :exchange, :sector, :logo_url)
    end
  end
end
