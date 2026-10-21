# Probe only (scope probe-assistant-stream). Markers print only on success,
# because the scope's gates read them.
ASSISTANT_PROBE_TTFT_BUDGET = 3.0

namespace :assistant_probe do
  def report(run)
    puts format("%-9s ttft %5.2fs  total %5.2fs  %4d chars  %d flushes  gate %s",
                run.provider, run.ttft.to_f, run.total, run.answer.size, run.flushes,
                run.gate.ok? ? "ok" : "INVENTED #{run.gate.invented.join(", ")}")
    puts "  Q: #{run.question}", "  A: #{run.answer.squish}"
  end

  desc "One grounded answer from a provider (shellm | anthropic), timed"
  task :run, [ :provider ] => :environment do |_, args|
    run = AssistantProbeJob.perform_now(args[:provider], Assistant::Domain::ProbePrompt::QUESTIONS.first)
    report(run)
    puts "PROBE #{run.provider} TTFT_OK" if run.ttft && run.ttft < ASSISTANT_PROBE_TTFT_BUDGET && run.gate.ok?
  end

  desc "Every probe question through every provider with credentials; counts grounded answers"
  task grounding: :environment do
    counts = AssistantProbeJob::PROVIDERS.keys.filter_map do |provider|
      runs = Assistant::Domain::ProbePrompt::QUESTIONS.map { |q| AssistantProbeJob.perform_now(provider, q) }
      runs.each { |r| report(r) }
      ttfts = runs.filter_map(&:ttft).sort
      puts format("%s: %d/%d grounded · ttft median %.2fs, max %.2fs", provider, runs.count { _1.gate.ok? },
                  runs.size, ttfts[ttfts.size / 2], ttfts.last)
      [ provider, runs.count { _1.gate.ok? } ]
    rescue KeyError => e
      puts "#{provider}: skipped, #{e.message}"
      nil
    end.to_h
    puts "GROUNDING anthropic>=9 shellm>=9" if counts.values_at("anthropic", "shellm").all? { _1.to_i >= 9 }
  end
end
