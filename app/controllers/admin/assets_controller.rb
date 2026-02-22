module Admin
  class AssetsController < BaseController
    include Pagy::Backend

    def index
      scope = Asset.all
      scope = scope.where(asset_type: params[:type]) if params[:type].present?
      scope = scope.where("name ILIKE :q OR symbol ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
      scope = scope.order(symbol: :asc)

      @pagy, @assets = pagy(scope, limit: 20, page: params[:page] || 1)
      @total_count   = Asset.count
      @syncing_count = Asset.syncing.count
    end

    def toggle_status
      result = Admin::Assets::ToggleStatus.call(asset_id: params[:id])

      if result.success?
        redirect_to admin_assets_path, notice: "Asset status updated."
      else
        redirect_to admin_assets_path, alert: result.failure.last
      end
    end
  end
end
