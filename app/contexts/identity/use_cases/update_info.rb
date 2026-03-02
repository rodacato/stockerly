module Identity
  class UpdateInfo < ApplicationUseCase
    def call(user:, params:)
      attrs = yield validate(Identity::UpdateProfileContract, params)
      _     = yield check_email_unique(user, attrs[:email])
      _     = yield persist(user, attrs)
      _     = yield publish(Identity::ProfileUpdated.new(user_id: user.id))

      Success(user)
    end

    private

    def check_email_unique(user, email)
      existing = User.where.not(id: user.id).find_by(email: email.downcase)
      existing ? Failure([ :validation, { email: [ "has already been taken" ] } ]) : Success(true)
    end

    def persist(user, attrs)
      user.update!(full_name: attrs[:full_name], email: attrs[:email])
      Success(user)
    rescue ActiveRecord::RecordInvalid => e
      Failure([ :validation, e.record.errors.to_hash ])
    end
  end
end
