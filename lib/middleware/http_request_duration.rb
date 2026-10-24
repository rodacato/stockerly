# Records http_request_duration_seconds for every request, labelled the way
# Node's prom-client middleware labels it, so one dashboard reads both stacks.
#
# The route is the Rails route pattern without its optional format suffix
# (`/market/:symbol`, never `/market/AAPL`) to keep label cardinality bounded.
class HttpRequestDuration
  UNMATCHED_ROUTE = "unmatched"

  def initialize(app)
    @app = app
  end

  def call(env)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status, headers, body = @app.call(env)
    record(env, status, started)
    [ status, headers, body ]
  rescue StandardError => e
    record(env, ActionDispatch::ExceptionWrapper.status_code_for_exception(e.class.name), started)
    raise
  end

  private

  def record(env, status, started)
    Yabeda.http_request_duration.measure(
      { method: env["REQUEST_METHOD"], route: route(env), status_code: status.to_s },
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    )
  end

  def route(env)
    ActionDispatch::Request.new(env).route_uri_pattern&.delete_suffix("(.:format)") || UNMATCHED_ROUTE
  end
end
