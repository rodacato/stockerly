class SearchController < AuthenticatedController
  def index
    result = Search::GlobalSearch.call(query: params[:q], user: current_user)

    case result
    in Dry::Monads::Success(data)
      @assets = data[:assets]
      @alerts = data[:alerts]
      @news   = data[:news]
      @query  = params[:q]
    end
  end
end
