module Profiles
  class ChangePassword < ApplicationUseCase
    def call(user:, params:)
      attrs = yield validate(Profiles::ChangePasswordContract, params)
      _     = yield verify_current_password(user, attrs[:current_password])
      _     = yield persist(user, attrs[:password], attrs[:password_confirmation])
      _     = yield publish(PasswordChanged.new(user_id: user.id))

      Success(user)
    end

    private

    def verify_current_password(user, password)
      user.authenticate(password) ? Success(true) : Failure([ :unauthorized, "Current password is incorrect" ])
    end

    def persist(user, new_password, confirmation)
      user.update!(password: new_password, password_confirmation: confirmation)
      Success(user)
    rescue ActiveRecord::RecordInvalid => e
      Failure([ :validation, e.record.errors.to_hash ])
    end
  end
end
