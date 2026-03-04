module Administration
  module UseCases
    module Users
      class DeleteUser < ApplicationUseCase
        def call(user_id:, admin:)
          target = User.find_by(id: user_id)
          return Failure([ :not_found, "User not found" ]) unless target
          return Failure([ :forbidden, "Cannot delete an admin" ]) if target.admin?

          user_data = { id: target.id, email: target.email, full_name: target.full_name }

          ActiveRecord::Base.transaction do
            AuditLog.where(user_id: target.id).delete_all
            target.destroy!
          end

          yield publish(Identity::Events::UserDeleted.new(
            user_id: user_data[:id],
            email: user_data[:email],
            full_name: user_data[:full_name],
            admin_id: admin.id
          ))

          Success(user_data)
        end
      end
    end
  end
end
