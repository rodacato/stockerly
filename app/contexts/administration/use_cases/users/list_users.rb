module Administration
  module UseCases
    module Users
      class ListUsers < ApplicationUseCase
        include Pagy::Method

        def call(params: {}, request: nil)
          scope = User.all
          scope = scope.where("full_name ILIKE :q OR email ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
          scope = scope.order(created_at: :desc)

          pagy, users = pagy(:offset, scope,
            limit: 20,
            page: params[:page] || 1,
            request: request || { base_url: "", path: "", params: {}, cookie: nil }
          )

          Success({
            pagy: pagy,
            users: users
          })
        end
      end
    end
  end
end
