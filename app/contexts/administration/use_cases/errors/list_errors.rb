module Administration
  module UseCases
    module Errors
      class ListErrors < SimpleUseCase
        include Pagy::Method

        def call(params: {}, request: nil)
          scope = ErrorEvent.recent.by_source(params[:source])
          scope = apply_search(scope, params[:search])

          pagy, errors = pagy(:offset, scope,
            limit: 50,
            page: params[:page] || 1,
            request: request || { base_url: "", path: "", params: {}, cookie: nil }
          )

          { pagy: pagy, errors: errors }
        end

        private

        # Same LIKE escaping as ListLogs: a query with % or _ must match
        # literally, not as a wildcard.
        def apply_search(scope, query)
          return scope if query.blank?

          like = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
          scope.where(
            "exception_class ILIKE :q OR message ILIKE :q OR request_path ILIKE :q OR reference ILIKE :q",
            q: like
          )
        end
      end
    end
  end
end
