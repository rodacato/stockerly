# Prometheus instrumentation via Yabeda — OPT-IN.
#
# The whole feature is off unless METRICS_TOKEN is set. An operator (or a fork
# that doesn't want metrics) does nothing and gets nothing wired up: no
# endpoint, no middleware, no data store, no overhead. Setting the token both
# enables the feature and secures the endpoint, which is scraped at GET /metrics
# by any external Prometheus over HTTPS — no coupling to private networking.
return if ENV["METRICS_TOKEN"].blank?

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
