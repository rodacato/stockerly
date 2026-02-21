class AlertsController < AuthenticatedController
  def index; end

  def create
    redirect_to alerts_path, notice: "Alert created (demo mode)."
  end

  def update
    redirect_to alerts_path, notice: "Alert updated (demo mode)."
  end

  def destroy
    redirect_to alerts_path, notice: "Alert deleted (demo mode)."
  end
end
