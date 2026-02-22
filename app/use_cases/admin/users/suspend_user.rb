module Admin
  module Users
    class SuspendUser < ApplicationUseCase
      def call(user_id:, admin:)
        target = User.find_by(id: user_id)
        return Failure([:not_found, "User not found"]) unless target
        return Failure([:forbidden, "Cannot suspend an admin"]) if target.admin?
        return Failure([:already_suspended, "User already suspended"]) if target.suspended?

        target.update!(status: :suspended)

        publish(UserSuspended.new(user_id: target.id, email: target.email, admin_id: admin.id))

        Success(target)
      end
    end
  end
end
