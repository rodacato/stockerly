module Admin
  class InvitesController < BaseController
    def index
      @invites = InviteCode.includes(:used_by_user, :created_by_user).order(created_at: :desc)
      @just_created_code = flash[:just_created_code]
    end

    def create
      result = Administration::UseCases::Invites::GenerateInviteCode.call(
        admin: current_user,
        note: params[:note]
      )

      case result
      in Dry::Monads::Success(invite)
        flash[:just_created_code] = invite.code
        redirect_to admin_invites_path, notice: "Código generado."
      in Dry::Monads::Failure[ :forbidden, message ]
        redirect_to admin_invites_path, alert: message
      end
    end
  end
end
