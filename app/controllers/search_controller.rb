class SearchController < AuthenticatedController
  def index
    result = Identity::GlobalSearch.call(query: params[:q], user: current_user)

    case result
    in Dry::Monads::Success(data)
      @assets = data[:assets]
      @alerts = data[:alerts]
      @news   = data[:news]
      @query  = params[:q]
    end

    if params[:format] == "modal"
      render partial: "search/modal_results", layout: false
    end
  end
end
