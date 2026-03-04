module Administration
  module UseCases
    module Users
      class ReactivateUser < ApplicationUseCase
        def call(user_id:, admin:)
          target = User.find_by(id: user_id)
          return Failure([ :not_found, "User not found" ]) unless target
          return Failure([ :forbidden, "Cannot reactivate an admin" ]) if target.admin?
          return Failure([ :not_suspended, "User is not suspended" ]) unless target.suspended?

          target.update!(status: :active)

          yield publish(Identity::Events::UserReactivated.new(user_id: target.id, email: target.email, admin_id: admin.id))

          Success(target)
        end
      end
    end
  end
end
