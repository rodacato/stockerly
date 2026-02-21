class ProfilesController < AuthenticatedController
  def show; end

  def update
    redirect_to profile_path, notice: "Profile updated (demo mode)."
  end
end
