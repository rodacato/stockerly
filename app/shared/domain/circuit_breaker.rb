# Lightweight circuit breaker for external API gateways.
# States: closed (normal) → open (failing) → half_open (testing recovery).
#
# Usage:
#   breaker = CircuitBreaker.new(name: "polygon", threshold: 5, timeout: 60)
#   breaker.call { gateway.fetch_price("AAPL") }
#
class CircuitBreaker
  include Dry::Monads[:result]

  STATES = %i[closed open half_open].freeze

  attr_reader :name, :state, :failure_count

  def initialize(name:, threshold: 5, timeout: 60)
    @name = name
    @threshold = threshold
    @timeout = timeout
    @state = :closed
    @failure_count = 0
    @last_failure_at = nil
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
  end

  private

  def execute(block)
    result = block.call

    if result.is_a?(Dry::Monads::Result) && result.failure?
      record_failure
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

    if @failure_count >= @threshold
      transition_to(:open)
    end
  end

  def record_success
    if @state == :half_open
      transition_to(:closed)
      @failure_count = 0
    end
  end

  def timeout_elapsed?
    @last_failure_at && Time.current - @last_failure_at >= @timeout
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
