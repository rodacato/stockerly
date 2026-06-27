# Prometheus instrumentation via Yabeda — OPT-IN.
#
# Two switches, both required to wire anything up:
#   METRICS_ENABLED  explicit on/off flag (truthy: 1/true/yes/on)
#   METRICS_TOKEN    bearer token securing the endpoint
#
# An operator (or a fork that doesn't want metrics) does nothing and gets
# nothing: no endpoint, no middleware, no data store, no overhead. The flag is
# separate from the token so metrics can be toggled off without deleting the
# secret. The endpoint is scraped at GET /metrics by any external Prometheus
# over HTTPS — no coupling to private networking. Enabling without a token
# fails closed (stays off) so metrics are never exposed unauthenticated.
metrics_enabled = %w[1 true yes on].include?(ENV["METRICS_ENABLED"].to_s.strip.downcase)

if metrics_enabled && ENV["METRICS_TOKEN"].blank?
  Rails.logger.warn("[metrics] METRICS_ENABLED is set but METRICS_TOKEN is blank — endpoint stays disabled (fail-closed).")
end

return unless metrics_enabled && ENV["METRICS_TOKEN"].present?

# Multiprocess aggregation: under clustered Puma (WEB_CONCURRENCY > 0) each
# worker — and the master, where the puma plugin collects server stats — writes
# to a shared file store so a single scrape reflects the whole instance.
# Single-process (dev/test) keeps the default in-memory store.
if ENV.fetch("WEB_CONCURRENCY", 0).to_i.positive?
  require "prometheus/client/data_stores/direct_file_store"

  multiproc_dir = Rails.root.join("tmp/prometheus")
  FileUtils.rm_rf(multiproc_dir)
  FileUtils.mkdir_p(multiproc_dir)

  Prometheus::Client.config.data_store =
    Prometheus::Client::DataStores::DirectFileStore.new(dir: multiproc_dir)
end

Yabeda.configure do
  group :stockerly

  gauge :data_age,
        unit: "seconds",
        comment: "Age in seconds of the freshest market-data sync (price/indices/fx)"

  collect do
    age = DataFreshness.newest_data_age_seconds
    stockerly.data_age.set({}, age) if age
  end
end

# Not Zeitwerk-managed (lib/middleware is ignored in autoload_lib) so it can be
# referenced safely here at boot, before the autoloaders are fully wired.
require Rails.root.join("lib/middleware/metrics_endpoint")
Rails.application.config.middleware.use MetricsEndpoint
