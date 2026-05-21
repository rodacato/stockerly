module Administration
  module UseCases
    module Users
      class ListUsers < ApplicationUseCase
        include Pagy::Method

        ROLE_FILTERS   = %w[user admin].freeze
        STATUS_FILTERS = %w[active suspended unverified].freeze

        def call(params: {}, request: nil)
          scope = User.all
          scope = scope.where("full_name ILIKE :q OR email ILIKE :q", q: "%#{params[:search]}%") if params[:search].present?
          scope = apply_role_filter(scope, params[:role])
          scope = apply_status_filter(scope, params[:status])
          scope = scope.order(created_at: :desc)

          pagy, users = pagy(:offset, scope,
            limit: 20,
            page: params[:page] || 1,
            request: request || { base_url: "", path: "", params: {}, cookie: nil }
          )

          Success({
            pagy: pagy,
            users: users,
            total_count: User.count,
            admin_count: User.admins.count
          })
        end

        private

        def apply_role_filter(scope, role)
          return scope unless ROLE_FILTERS.include?(role.to_s)
          scope.where(role: role)
        end

        # "unverified" is not a true status enum — it is a verification state
        # (email_verified_at IS NULL). We collapse it into the same filter
        # chip group because the admin treats it as a third lifecycle state.
        def apply_status_filter(scope, status)
          case status.to_s
          when "active"     then scope.where(status: :active).where.not(email_verified_at: nil)
          when "suspended"  then scope.where(status: :suspended)
          when "unverified" then scope.where(email_verified_at: nil)
          else                   scope
          end
        end
      end
    end
  end
end
