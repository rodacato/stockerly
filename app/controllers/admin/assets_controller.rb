module Admin
  class AssetsController < BaseController
    rate_limit to: 5, within: 1.minute, only: :trigger_sync
    rate_limit to: 10, within: 1.minute, only: :create
    rate_limit to: 15, within: 1.minute, only: :search

    def index
      result = Administration::UseCases::Assets::ListAssets.call(params: filter_params)
      data = result.value!

      @pagy          = data[:pagy]
      @assets        = data[:assets]
      @total_count   = data[:total_count]
      @syncing_count = data[:syncing_count]
    end

    def trigger_sync
      result = Administration::UseCases::Assets::TriggerSync.call(asset_id: params[:id])

      if result.success?
        redirect_to admin_assets_path, notice: "Sync job enqueued."
      else
        redirect_to admin_assets_path, alert: result.failure.last
      end
    end

    def trigger_sync_all
      result = Administration::UseCases::Assets::TriggerSync.call(asset_type: params[:type])

      if result.success?
        redirect_to admin_assets_path, notice: "Bulk sync enqueued."
      else
        redirect_to admin_assets_path, alert: "Failed to enqueue sync."
      end
    end

    def search
      result = Administration::UseCases::Assets::SearchTicker.call(query: params[:q])

      if result.success?
        render json: result.value!
      else
        render json: { error: result.failure.last }, status: :unprocessable_content
      end
    end

    def create
      result = Administration::UseCases::Assets::CreateAsset.call(admin: current_user, params: asset_params.to_h)

      if result.success?
        redirect_to admin_assets_path, notice: "Asset \"#{result.value!.symbol}\" created successfully."
      else
        redirect_to admin_assets_path, alert: result.failure.last.is_a?(Hash) ? result.failure.last.values.flatten.first : result.failure.last
      end
    end

    def destroy
      result = Administration::UseCases::Assets::DeleteAsset.call(asset_id: params[:id], admin: current_user)

      if result.success?
        redirect_to admin_assets_path, notice: "Asset \"#{result.value!}\" deleted."
      else
        redirect_to admin_assets_path, alert: result.failure.last
      end
    end

    def toggle_status
      result = Administration::UseCases::Assets::ToggleStatus.call(asset_id: params[:id])

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
