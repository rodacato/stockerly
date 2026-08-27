# WebMock stops a spec reaching a provider over HTTP. It cannot stop one that
# shells out: the yfinance bridge runs Python in a subprocess, so a missing stub
# calls Yahoo for real from CI. ADR-017 records the rule and a spec still slipped
# through it — the "all gateways fail" context had lost its stub and was hitting
# the network. A rule nobody can enforce is not a rule.
#
# Specs that need the real runner declare it: `it "...", :real_subprocess do`.
# `lib/python/probe.py` has no dependency and no network, which is what makes
# PythonRunner's own specs safe to run for real.
RSpec.configure do |config|
  config.before do |example|
    next if example.metadata[:real_subprocess]

    allow(PythonRunner).to receive(:call) do |script, *args|
      raise <<~MESSAGE
        This spec reached PythonRunner for real: #{script} #{args.join(' ')}

        A subprocess bypasses WebMock, so this would have called the provider
        from CI. Stub it with one of the stub_yfinance_* helpers, or mark the
        example :real_subprocess if it genuinely needs the runner.
      MESSAGE
    end
  end
end
