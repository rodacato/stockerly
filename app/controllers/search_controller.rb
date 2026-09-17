class SearchController < AuthenticatedController
  DROPDOWN = "search_dropdown".freeze

  # D125: the catalogue answers first and Yahoo only when it has nothing, or
  # when asked for another listing of a symbol the catalogue already holds.
  def show
    @query = params[:q].to_s.strip
    @catalogue = Trading::UseCases::SearchCatalogue.call(user: current_user, query: @query)
    @asked_yahoo = @query.length >= Trading::UseCases::SearchCatalogue::MIN_LENGTH &&
                   (@catalogue.empty? || params[:scope] == "yahoo")
    @yahoo = []
    @yahoo_failed = false
    search_yahoo if @asked_yahoo

    render partial: "search/dropdown", layout: false if turbo_frame_request_id == DROPDOWN
  end

  private

  def search_yahoo
    # The Success holds an array, which pattern matching would destructure.
    result = Administration::UseCases::Assets::SearchTicker.call(query: @query)
    return @yahoo_failed = true if result.failure?

    tracked = Asset.where(symbol: result.value!.pluck(:symbol)).pluck(:symbol).to_set
    @yahoo = result.value!.reject { |listing| tracked.include?(listing[:symbol]) }
  end
end
