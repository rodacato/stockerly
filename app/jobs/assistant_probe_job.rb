# Probe only (scope probe-assistant-stream): composes one answer, broadcasts it
# in throttled chunks, and returns the timings the probe's gates read.
class AssistantProbeJob < ApplicationJob
  STREAM = "assistant_probe".freeze
  FLUSH_EVERY = 0.3

  Run = Data.define(:provider, :question, :answer, :ttft, :total, :flushes, :gate)

  PROVIDERS = {
    "shellm" => -> { [ ENV.fetch("SHELLM_BASE_URL"), ENV.fetch("SHELLM_API_KEY"), ENV.fetch("PROBE_MODEL", "claude-sonnet") ] },
    "anthropic" => -> { [ "https://api.anthropic.com", ENV.fetch("ANTHROPIC_PROBE_API_KEY"), ENV.fetch("PROBE_ANTHROPIC_MODEL", "claude-sonnet-5-5") ] }
  }.freeze

  def perform(provider, question)
    base_url, key, model = PROVIDERS.fetch(provider).call
    gateway = Assistant::Gateways::AnthropicMessages.new(base_url:, api_key: key, model:)
    answer, pending, flushes = +"", +"", 0
    started = last_flush = monotonic
    ttft = nil

    gateway.stream(system: Assistant::Domain::ProbePrompt.system, messages: [ { role: "user", content: question } ]) do |text|
      ttft ||= monotonic - started
      answer << text
      pending << text
      next if monotonic - last_flush < FLUSH_EVERY

      flushes += broadcast(pending)
      last_flush = monotonic
    end
    flushes += broadcast(pending)

    gate = Assistant::Domain::NumbersGate.call(answer:, context: Assistant::Domain::ProbePrompt::CONTEXT)
    Run.new(provider:, question:, answer:, ttft:, total: monotonic - started, flushes:, gate:)
  end

  private

  def broadcast(text)
    return 0 if text.empty?

    Turbo::StreamsChannel.broadcast_append_to(STREAM, target: "answer", html: ERB::Util.html_escape(text))
    text.clear
    1
  end

  def monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)
end
