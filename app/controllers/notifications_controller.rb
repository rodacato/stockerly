class NotificationsController < AuthenticatedController
  def index
    data = Notifications::UseCases::ListRecent.call(
      user:   current_user,
      tipo:   params[:tipo].presence   || "todos",
      estado: params[:estado].presence || "todos"
    )
    @notifications = data[:notifications]
    @counts        = data[:counts]
    @shown_count   = data[:shown_count]
    @tipo          = data[:tipo]
    @estado        = data[:estado]
  end

  def mark_as_read
    result = Notifications::UseCases::MarkAsRead.call(user: current_user, notification_id: params[:id])

    if result.success?
      redirect_to notifications_path, notice: t("notifications.flash.marcada_leida")
    else
      redirect_to notifications_path, alert: result.failure.last
    end
  end

  def mark_all_read
    Notifications::UseCases::MarkAsRead.call(user: current_user)
    redirect_to notifications_path, notice: t("notifications.flash.todas_leidas")
  end

  def destroy_read
    deleted = Notifications::UseCases::DestroyRead.call(user: current_user)
    redirect_to notifications_path, notice: t("notifications.flash.eliminadas", count: deleted)
  end
end
