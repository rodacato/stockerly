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
