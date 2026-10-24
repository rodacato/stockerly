require "rails_helper"

RSpec.describe HttpRequestDuration do
  def exposition
    Prometheus::Client::Formats::Text.marshal(Yabeda::Prometheus.registry)
  end

  it "records an exception as the status Rails would answer with, and re-raises it" do
    app = described_class.new(->(_env) { raise ActiveRecord::RecordNotFound })
    env = Rack::MockRequest.env_for("/assets/1", method: "DELETE")
    env["action_dispatch.route_uri_pattern"] = "/assets/:id(.:format)"

    expect { app.call(env) }.to raise_error(ActiveRecord::RecordNotFound)
    expect(exposition).to include('http_request_duration_seconds_count{method="DELETE",route="/assets/:id",status_code="404"}')
  end
end
