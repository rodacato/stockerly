class ApplicationUseCase
  include Dry::Monads[:result, :do]

  def self.call(...)
    new.call(...)
  end

  private

  def validate(contract_class, params)
    result = contract_class.new.call(params)
    result.success? ? Success(result.to_h) : Failure([ :validation, result.errors.to_h ])
  end

  def publish(event)
    EventBus.publish(event)
    Success(event)
  end
end
