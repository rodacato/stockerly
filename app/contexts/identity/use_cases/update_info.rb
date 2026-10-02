module Identity
  module UseCases
    class UpdateInfo < ApplicationUseCase
      def call(user:, params:, current_password: nil)
        attrs = yield validate(Contracts::UpdateProfileContract, params)
        _     = yield verify_current_password(user, attrs[:email], current_password)
        _     = yield check_email_unique(user, attrs[:email])
        _     = yield persist(user, attrs)
        _     = yield publish(Events::ProfileUpdated.new(user_id: user.id))

        Success(user)
      end

      private

      def verify_current_password(user, email, password)
        return Success(true) if email.downcase.strip == user.email
        return Success(true) if password.present? && user.authenticate(password)

        Failure([ :unauthorized, "Current password is required to change the email" ])
      end

      def check_email_unique(user, email)
        existing = User.where.not(id: user.id).find_by(email: email.downcase)
        existing ? Failure([ :validation, { email: [ "has already been taken" ] } ]) : Success(true)
      end

      def persist(user, attrs)
        update_attrs = { full_name: attrs[:full_name], email: attrs[:email] }
        update_attrs[:preferred_currency] = attrs[:preferred_currency] if attrs[:preferred_currency].present?
        user.update!(update_attrs)
        Success(user)
      rescue ActiveRecord::RecordInvalid => e
        Failure([ :validation, e.record.errors.to_hash ])
      end
    end
  end
end
