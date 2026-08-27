# `DataSourceRegistry` is filled once at boot and read by every routing
# decision, so a spec that registers a source hands it to every spec that runs
# after it — and only in the orders where it happens to run first.
#
# `spec/tasks/sync_rake_spec.rb` registers a `:test_source` for `:prices` whose
# gateway is the abstract base class. Under `--seed 111` four unrelated specs
# then failed with `NotImplementedError` raised from inside GatewayChain, which
# reads like a routing bug and is not one.
#
# The baseline is a local shared by both hooks on purpose: `before(:suite)` and
# `before(:each)` run in different scopes, so an instance variable set in the
# first is nil in the second.
baseline = nil

RSpec.configure do |config|
  config.before(:suite) { baseline = DataSourceRegistry.snapshot }

  # A group tagged `:manages_registry` owns the contents itself; restoring the
  # boot sources inside an example that just cleared them would fight it.
  config.before(:each) do |example|
    next if example.metadata[:manages_registry]

    DataSourceRegistry.restore(baseline) if baseline
  end
end
