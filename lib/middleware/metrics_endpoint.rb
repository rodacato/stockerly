require "yabeda/prometheus/exporter"

# Serves Prometheus metrics at /metrics, gated by a bearer token.
#
# The app sits behind kamal-proxy on a public hostname, so an ordinary route
# would expose metrics to the internet. Instead this middleware intercepts
# /metrics before routing and requires `Authorization: Bearer <METRICS_TOKEN>`.
# When METRICS_TOKEN is unset the endpoint returns 404 — fail closed, never
# expose metrics unprotected by accident.
class MetricsEndpoint
  PATH = "/metrics"

  def initialize(app)
    @app = app
    @exporter = Yabeda::Prometheus::Exporter.new(
      ->(_env) { not_found },
      path: PATH
    )
  end

  def call(env)
    return @app.call(env) unless env["PATH_INFO"] == PATH
    return not_found if token.blank?
    return unauthorized unless authorized?(env)

    @exporter.call(env)
  end

  private

  def token
    ENV["METRICS_TOKEN"]
  end

  def authorized?(env)
    presented = env["HTTP_AUTHORIZATION"].to_s.delete_prefix("Bearer ")
    return false if presented.empty?

    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(presented),
      ::Digest::SHA256.hexdigest(token)
    )
  end

  def unauthorized
    [ 401, { "Content-Type" => "text/plain", "WWW-Authenticate" => "Bearer" }, [ "Unauthorized\n" ] ]
  end

  def not_found
    [ 404, { "Content-Type" => "text/plain" }, [ "Not Found\n" ] ]
  end
end
