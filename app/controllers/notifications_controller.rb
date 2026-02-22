class NotificationsController < AuthenticatedController
  def index
    @notifications = current_user.notifications.recent
    @unread_count  = current_user.notifications.unread.count
  end

  def mark_as_read
    result = Notifications::MarkAsRead.call(user: current_user, notification_id: params[:id])

    if result.success?
      redirect_to notifications_path, notice: "Notification marked as read."
    else
      redirect_to notifications_path, alert: result.failure.last
    end
  end

  def mark_all_read
    Notifications::MarkAsRead.call(user: current_user)
    redirect_to notifications_path, notice: "All notifications marked as read."
  end
end
