class DashboardController < AuthenticatedController
  def show
    result = Dashboard::Assemble.call(user: current_user)

    if result.success?
      data = result.value!
      @summary         = data[:summary]
      @watchlist_items = data[:watchlist_items]
      @news            = data[:news]
      @trending        = data[:trending]
      @indices         = data[:indices]
      @sentiment       = data[:sentiment]
    end
  end
end
