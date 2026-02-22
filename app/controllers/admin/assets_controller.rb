module Admin
  class AssetsController < BaseController
    def index
      result = Admin::Assets::ListAssets.call(params: filter_params)
      data = result.value!

      @pagy          = data[:pagy]
      @assets        = data[:assets]
      @total_count   = data[:total_count]
      @syncing_count = data[:syncing_count]
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
  end
end
