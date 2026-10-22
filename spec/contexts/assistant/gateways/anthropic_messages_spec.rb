require "rails_helper"

RSpec.describe Assistant::Gateways::AnthropicMessages::EventStream do
  let(:wire) do
    <<~SSE
      event: message_start
      data: {"type":"message_start","message":{"id":"msg_1"}}

      event: content_block_delta
      data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"El RSI"}}

      event: ping
      data: {"type":"ping"}

      event: content_block_delta
      data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" está en 72.4"}}

    SSE
  end

  def events_from(chunks)
    stream = described_class.new
    chunks.flat_map { |chunk| [].tap { |out| stream.feed(chunk) { |e| out << e } } }
  end

  it "yields the same events however the wire is cut" do
    whole = events_from([ wire ])
    cut = events_from(wire.chars.each_slice(7).map(&:join))

    expect(cut).to eq(whole)
    expect(whole.pluck("type")).to eq(%w[message_start content_block_delta ping content_block_delta])
  end

  it "holds back an event until its blank line arrives" do
    half = wire[0, wire.index("event: ping")]

    expect(events_from([ half.chomp ]).size).to eq(1)
  end
end

RSpec.describe Assistant::Gateways::AnthropicMessages, "#verify" do
  let(:api_key) { "sk-test-secret" }
  let(:endpoint) { "https://llm.example.test/v1/messages" }
  let(:gateway) { described_class.new(base_url: "https://llm.example.test", api_key:, model: "claude-test") }

  def error_body(message) = { type: "error", error: { type: "x", message: } }.to_json

  it "sends one non-streaming request of a single token with the provider headers" do
    headers = { "x-api-key" => api_key, "anthropic-version" => "2023-06-01", "content-type" => "application/json" }
    stub = stub_request(:post, endpoint).with(headers:) { |req|
      body = JSON.parse(req.body)
      body["max_tokens"] == 1 && body["model"] == "claude-test" && !body.key?("stream") && body["messages"].size == 1
    }.to_return(status: 200, body: { type: "message" }.to_json)

    gateway.verify

    expect(stub).to have_been_requested.once
  end

  it "reports :ok when the provider answers" do
    stub_request(:post, endpoint).to_return(status: 200, body: { type: "message" }.to_json)

    expect(gateway.verify).to eq(described_class::Verification.new(status: :ok, detail: nil))
  end

  it "reports :unauthorized on a 401 or a 403" do
    stub_request(:post, endpoint).to_return({ status: 401, body: error_body("invalid x-api-key") }, { status: 403, body: "" })

    expect([ gateway.verify.status, gateway.verify.status ]).to eq(%i[unauthorized unauthorized])
  end

  it "reports :not_found on a 404, with the provider's message" do
    stub_request(:post, endpoint).to_return(status: 404, body: error_body("model: claude-nope"))

    expect(gateway.verify).to have_attributes(status: :not_found, detail: "model: claude-nope")
  end

  it "reports :failed with the provider's message for any other error status" do
    stub_request(:post, endpoint).to_return(status: 529, body: error_body("Overloaded"))

    expect(gateway.verify).to have_attributes(status: :failed, detail: "Overloaded")
  end

  it "falls back to the status when the error body is not JSON" do
    stub_request(:post, endpoint).to_return(status: 502, body: "<html>Bad Gateway</html>")

    expect(gateway.verify).to have_attributes(status: :failed, detail: "502")
  end

  it "never echoes the API key back in the detail" do
    stub_request(:post, endpoint).to_return(status: 400, body: error_body("bad key #{api_key}"))

    expect(gateway.verify.detail).to eq("bad key [redacted]")
  end

  it "reports :timeout when the connection does not open in time" do
    stub_request(:post, endpoint).to_timeout

    expect(gateway.verify.status).to eq(:timeout)
  end

  it "reports :timeout when the answer does not arrive in time" do
    stub_request(:post, endpoint).to_raise(Net::ReadTimeout)

    expect(gateway.verify.status).to eq(:timeout)
  end

  it "reports :unreachable when the host refuses the connection" do
    stub_request(:post, endpoint).to_raise(Errno::ECONNREFUSED)

    expect(gateway.verify.status).to eq(:unreachable)
  end
end
