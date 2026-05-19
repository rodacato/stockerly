module Identity
  module UseCases
    class ResetPassword < ApplicationUseCase
      def call(token:, params:)
        user = User.find_by_password_reset_token(token)
        return Failure([ :invalid_token ]) unless user

        contract_result = Contracts::ResetPasswordContract.new.call(params)
        unless contract_result.success?
          attach_errors(user, contract_result.errors.to_h)
          return Failure([ :validation, user ])
        end

        attrs = contract_result.to_h
        unless user.update(password: attrs[:password], password_confirmation: attrs[:password_confirmation])
          return Failure([ :validation, user ])
        end

        user.remember_tokens.destroy_all

        Success(user)
      end

      private

      # Mirror contract failure messages onto the user's ActiveModel::Errors
      # so the form can re-render with `@user.errors.full_messages` from a
      # single source.
      def attach_errors(user, contract_errors)
        contract_errors.each do |field, messages|
          messages.each { |msg| user.errors.add(field, msg) }
        end
      end
    end
  end
end
