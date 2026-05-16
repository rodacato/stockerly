module Administration
  module UseCases
    module Invites
      class GenerateInviteCode < ApplicationUseCase
        def call(admin:, note: nil)
          return Failure([ :forbidden, "Only admins can generate invite codes" ]) unless admin&.admin?

          invite = InviteCode.create!(
            code: InviteCode.generate_code,
            note: note.presence,
            created_by_user: admin
          )

          Success(invite)
        end
      end
    end
  end
end
