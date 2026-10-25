require "rails_helper"
require "prometheus/client/data_stores/direct_file_store"
require "prometheus/client/formats/text"

# Clustered Puma uses the file store (config/initializers/yabeda.rb); every other spec runs on the in-memory one.
RSpec.describe "Prometheus multi-process file store" do
  around do |example|
    original = Prometheus::Client.config.data_store
    Dir.mktmpdir do |dir|
      Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: dir)
      example.run
    ensure
      Prometheus::Client.config.data_store = original
    end
  end

  it "renders a histogram observed through it" do
    registry = Prometheus::Client::Registry.new
    histogram = registry.histogram(:http_request_duration_seconds,
                                   docstring: "HTTP request duration",
                                   labels: %i[method route status_code])
    histogram.observe(0.12, labels: { method: "GET", route: "/market/:symbol", status_code: "200" })

    exposition = Prometheus::Client::Formats::Text.marshal(registry)

    expect(exposition).to include('http_request_duration_seconds_count{method="GET",route="/market/:symbol",status_code="200"} 1.0')
  end
end
