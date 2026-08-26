# Lightweight circuit breaker for external API gateways.
# States: closed (normal) → open (failing) → half_open (testing recovery).
#
# Usage:
#   breaker = CircuitBreaker.new(name: "alpaca", threshold: 5, timeout: 60)
#   breaker.call { gateway.fetch_price("AAPL") }
#
class CircuitBreaker
  include Dry::Monads[:result]

  STATES = %i[closed open half_open].freeze

  attr_reader :name, :state, :failure_count

  # A permanent failure opens the breaker on the first occurrence rather than
  # the fifth, and holds it open far longer. Retrying "your plan does not
  # include this" every 60 seconds spends quota to be told no again — which is
  # what a free Finnhub key hitting the premium candles endpoint did forever.
  #
  # It still expires. Entitlements change when someone upgrades a plan or fixes
  # a key, and a misclassified failure must not strand a working provider until
  # the process restarts.
  PERMANENT_TIMEOUT = 1.hour.to_i

  def initialize(name:, threshold: 5, timeout: 60, permanent_timeout: PERMANENT_TIMEOUT)
    @name = name
    @threshold = threshold
    @timeout = timeout
    @permanent_timeout = permanent_timeout
    @state = :closed
    @failure_count = 0
    @last_failure_at = nil
    @open_for = timeout
  end

  def call(&block)
    case @state
    when :closed
      execute(block)
    when :open
      if timeout_elapsed?
        transition_to(:half_open)
        execute(block)
      else
        Failure([ :circuit_open, "Circuit breaker '#{@name}' is open" ])
      end
    when :half_open
      execute(block)
    end
  end

  def reset!
    @state = :closed
    @failure_count = 0
    @last_failure_at = nil
    @open_for = @timeout
  end

  private

  def execute(block)
    result = block.call

    if result.is_a?(Dry::Monads::Result) && result.failure?
      GatewayFailure.permanent?(failure_tag(result)) ? record_permanent_failure : record_failure
    else
      record_success
    end

    result
  rescue StandardError => e
    record_failure
    Failure([ :gateway_error, e.message ])
  end

  def record_failure
    @failure_count += 1
    @last_failure_at = Time.current
    @open_for = @timeout

    transition_to(:open) if @failure_count >= @threshold
  end

  def record_permanent_failure
    @failure_count = @threshold
    @last_failure_at = Time.current
    @open_for = @permanent_timeout

    transition_to(:open)
  end

  def record_success
    return unless @state == :half_open

    transition_to(:closed)
    @failure_count = 0
    @open_for = @timeout
  end

  def failure_tag(result)
    failure = result.failure
    failure.is_a?(Array) ? failure.first : failure
  end

  def timeout_elapsed?
    @last_failure_at && Time.current - @last_failure_at >= @open_for
  end

  def transition_to(new_state)
    old_state = @state
    @state = new_state

    log_transition(old_state, new_state) if old_state != new_state
  end

  def log_transition(from, to)
    SystemLog.create!(
      task_name: "Circuit Breaker: #{@name}",
      module_name: "resilience",
      severity: to == :open ? :warning : :success,
      error_message: "Transitioned from #{from} to #{to}",
      duration_seconds: 0
    )
  rescue ActiveRecord::ActiveRecordError
    # Don't let logging failures break the circuit breaker
  end
end
