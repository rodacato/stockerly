# Per-block AR query counter for N+1 regression tests (S04 retro carry-over).
#
# Usage:
#   queries = count_queries { use_case.call }
#   expect(queries).to be <= 5
#
# Or, the matcher form:
#   expect { use_case.call }.to make_queries(count: 5)
#   expect { use_case.call }.to make_queries(at_most: 7)
#
# Excludes CACHE, SCHEMA, and TRANSACTION queries — those are noise from
# fixture setup / cache hits / surrounding transactions and would make
# the matcher brittle to test-harness changes.
module QueryCounter
  IGNORE = /\A(?:CACHE|SCHEMA|BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE SAVEPOINT)/.freeze

  def count_queries
    queries = []
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_n, _s, _f, _id, payload|
      next if payload[:name] == "SCHEMA"
      next if IGNORE.match?(payload[:sql])
      queries << payload[:sql]
    end
    yield
    queries.size
  ensure
    ActiveSupport::Notifications.unsubscribe(sub) if sub
  end
end

RSpec::Matchers.define :make_queries do |expected|
  match do |block|
    @count = nil
    queries = []
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_n, _s, _f, _id, payload|
      next if payload[:name] == "SCHEMA"
      next if QueryCounter::IGNORE.match?(payload[:sql])
      queries << payload[:sql]
    end
    block.call
    ActiveSupport::Notifications.unsubscribe(sub)
    @count = queries.size

    if expected[:count]
      @count == expected[:count]
    elsif expected[:at_most]
      @count <= expected[:at_most]
    elsif expected[:at_least]
      @count >= expected[:at_least]
    else
      false
    end
  end

  supports_block_expectations

  failure_message do |_block|
    expected_str = expected[:count] ? "exactly #{expected[:count]}" : expected[:at_most] ? "at most #{expected[:at_most]}" : "at least #{expected[:at_least]}"
    "expected block to make #{expected_str} queries, made #{@count}"
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end
