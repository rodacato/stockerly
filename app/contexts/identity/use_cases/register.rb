module Identity
  module UseCases
    class Register < ApplicationUseCase
      def call(params:)
        attrs = yield validate(Contracts::RegisterContract, params)
        user  = yield persist_with_invite(attrs)
        _     = yield publish(Events::UserRegistered.new(user_id: user.id, email: user.email))

        Success(user)
      end

      private

      # Single generic error message for invalid / used / expired invite
      # codes — defeats enumeration. An attacker cannot tell from the error
      # whether a code never existed, was already redeemed, or has aged out.
      INVITE_GENERIC_ERROR = "código de invitación inválido o ya usado".freeze

      def persist_with_invite(attrs)
        normalized = InviteCode.normalize(attrs[:invite_code])

        ActiveRecord::Base.transaction do
          invite = InviteCode.lock.find_by(code: normalized)

          return Failure([ :validation, { invite_code: [ INVITE_GENERIC_ERROR ] } ]) unless invite&.redeemable?

          user = User.new(
            full_name: attrs[:full_name],
            email: attrs[:email],
            password: attrs[:password],
            password_confirmation: attrs[:password_confirmation],
            consents_data_processing_at: Time.current
          )

          return Failure([ :validation, user.errors.to_hash ]) unless user.save

          invite.update!(used_at: Time.current, used_by_user: user)

          Success(user)
        end
      end
    end
  end
end
