# ADR-032: the browser may report only the events the catalogue marks as
# client-side (a link leaving the app); every other event is recorded server-side.
class UsageEventsController < AuthenticatedController
  def create
    return head :unprocessable_content unless Usage::Domain::Catalogue.client?(params[:name])

    Usage.record(params[:name], screen: params[:screen])
    head :no_content
  end
end
