module Identity
  class Register < ApplicationUseCase
    def call(params:)
      attrs = yield validate(Identity::RegisterContract, params)
      user  = yield persist(attrs)
      _     = yield publish(UserRegistered.new(user_id: user.id, email: user.email))

      Success(user)
    end

    private

    def persist(attrs)
      user = User.new(
        full_name: attrs[:full_name],
        email: attrs[:email],
        password: attrs[:password],
        password_confirmation: attrs[:password_confirmation]
      )
      user.save ? Success(user) : Failure([ :validation, user.errors.to_hash ])
    end
  end
end
