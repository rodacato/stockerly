module Admin
  module Users
    class ListUsers < ApplicationUseCase
      include Pagy::Backend

      def call(params: {})
        scope = User.all
        scope = scope.where("full_name ILIKE :q OR email ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
        scope = scope.order(created_at: :desc)

        pagy, users = pagy(scope, limit: 20, page: params[:page] || 1)

        Success({
          pagy: pagy,
          users: users
        })
      end
    end
  end
end
